class ExportersController < ApplicationController
  before_action :set_exporter, only: [:show, :edit, :update, :destroy]
  before_filter :set_treasury, only: [:index, :new]
  before_filter :set_model, except: [:index]
  before_filter :alias_params, only: [:create, :update]

  # GET /exporters
  def index
    return if needs_treasury_supervisor(@treasury)
    @exporters = @treasury.exporters.all
  end

  # GET /exporters/1
  def show
  end

  # GET /exporters/new
  def new
    @exporter = @model.new
    @exporter.treasury = @treasury
    return if needs_treasury_supervisor(@exporter.treasury)
  end

  # GET /exporters/1/edit
  def edit
  end

  # POST /exporters
  def create
    @exporter = @model.new(exporter_params)
    return if needs_treasury_supervisor(@exporter.treasury)
    
    if @exporter.save
      redirect_to treasury_exporters_path(@exporter.treasury), notice: 'Exporter was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /exporters/1
  def update
    if @exporter.update(exporter_params)
      redirect_to treasury_exporters_path(@exporter.treasury), notice: 'Exporter was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /exporters/1
  def destroy
    @exporter.destroy
    redirect_to treasury_exporters_path(@exporter.treasury), notice: 'Exporter was successfully destroyed.'
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_exporter
    @exporter = Exporter.find(params[:id])
    return if needs_treasury_supervisor(@exporter.treasury)
  end

  # Only allow a trusted parameter "white list" through.
  def exporter_params
    params[:exporter].permit(:treasury_id, :from, :to)
  end

  def set_treasury
    @treasury = Treasury.find(params[:treasury_id])
  end
  def set_model
    @model = params[:requirements][:class_name].constantize
  end
  def alias_params
    params[:exporter] = params[@model.model_name.singular.to_sym]
  end
end
