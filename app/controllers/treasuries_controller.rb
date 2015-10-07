class TreasuriesController < ApplicationController
  before_filter :needs_root, :except => [:index, :show]

  before_filter :set_model, :except => :index
  before_filter :alias_params, :only => [:create, :update]
  def set_model
    @model = params[:requirements][:class_name].constantize
  end
  def alias_params
    params[:treasury] = params[@model.model_name.singular.to_sym]
  end

  # GET /treasuries
  # GET /treasuries.json
  def index
    @treasuries = Treasury.all

    respond_to do |format|
      format.html
      format.json { render json: @treasuries }
    end
  end

  def show
    @treasury = Treasury.find(params[:id])
    return if needs_deeply_concerned(@treasury)

    if params[:filter_year]
      #start_date = Date.parse("%d-01-01" % params[:filter_year])
      end_date = Date.parse("%d-12-31" % params[:filter_year])
      #@transactions = @transactions.where("date BETWEEN ? AND ?", start_date, end_date)
      #@transactions = @transactions.where("date BETWEEN ? AND ?", start_date, end_date)
      Treasury.set_date_scope('2000-01-01', end_date)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @treasury }
    end
  ensure
    Treasury.reset_data_scope
  end

  # GET /treasuries/new
  # GET /treasuries/new.json
  def new
    @treasury = @model.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @treasury }
    end
  end

  # GET /treasuries/1/edit
  def edit
    @treasury = Treasury.find(params[:id])
  end

  # POST /treasuries
  # POST /treasuries.json
  def create
    @treasury = @model.new(treasury_params)

    respond_to do |format|
      if @treasury.save
        format.html { redirect_to root_path, notice: 'Treasury was successfully created.' }
        format.json { render json: @treasury, status: :created, location: @treasury }
      else
        format.html { render action: "new" }
        format.json { render json: @treasury.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /treasuries/1
  # PUT /treasuries/1.json
  def update
    @treasury = Treasury.find(params[:id])

    respond_to do |format|
      if @treasury.update_attributes(treasury_params)
        format.html { redirect_to root_path, notice: 'Treasury was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @treasury.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /treasuries/1
  # DELETE /treasuries/1.json
  def destroy
    @treasury = Treasury.find(params[:id])
    @treasury.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :no_content }
    end
  end

  private
  def treasury_params
    params.require(@model.model_name.singular.to_sym).permit(:name, supervisor_ids: [])
  end
end
