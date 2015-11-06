# encoding: utf-8
class CategoriesController < ApplicationController
  private
  before_filter :set_treasury, :only => [:index, :new]
  before_filter :set_model, :only => [:index, :new, :create, :update, :destroy]
  before_filter :alias_params, :only => [:create, :update]
  def set_treasury
    @treasury = Treasury.find(params[:treasury_id])
  end
  def set_model
    @model = params[:requirements][:class_name].constantize
  end
  def alias_params
    params[:category] = params[@model.model_name.singular.to_sym]
  end

  public

  # GET /categories
  # GET /categories.json
  def index
    return if needs_deeply_concerned(@treasury)

    @page_title = '/categories'
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @categories }
    end
  end

  # GET /categories/new
  # GET /categories/new.json
  def new
    @category = @model.new(:treasury => @treasury) #@treasury.categories.build
    @category.parent = Category.find(params[:parent_id]) if params[:parent_id]
    return if needs_deeply_concerned(@treasury)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @category }
    end
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])
    @treasury = @category.treasury
    return if needs_deeply_concerned(@treasury)
    return if needs_treasury_supervisor @treasury unless @category.titles.empty?
  end

  # POST /categories
  # POST /categories.json
  def create
    @category = @model.new(category_params)
    @treasury = @category.treasury
    return if needs_deeply_concerned(@treasury)

    respond_to do |format|
      if @category.save
        format.html { redirect_to index_path }
        format.json { render json: @category, status: :created, location: @category }
        format.js   { render text: 'Created', status: :created, location: @category }
      else
        format.html { render action: "new" }
        format.json { render json: { errors: @category.errors }, status: :unprocessable_entity }
        format.js   { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /categories/1
  # PUT /categories/1.json
  def update
    @category = Category.find(params[:id])
    @treasury = @category.treasury
    return if needs_deeply_concerned(@treasury)
    return if needs_treasury_supervisor @treasury unless @category.titles.empty?

    respond_to do |format|
      if @category.update_attributes(category_params)
        format.html { redirect_to index_path }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: { errors: @category.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.json
  def destroy
    @category = Category.find(params[:id])
    @treasury = @category.treasury
    return if needs_deeply_concerned(@treasury)
    return if needs_treasury_supervisor @treasury unless @category.titles.empty?
    @category.destroy

    respond_to do |format|
      format.html { redirect_to index_path }
      format.json { head :no_content }
    end
  end

  private
  def category_params
    params.require(:category).permit(
      :treasury_id, :business_id, :name, :parent_id, :exporter_id
    )
  end

  def index_path
    [@treasury.becomes(Treasury), @model.name.parameterize.underscore.pluralize]
  end
end
