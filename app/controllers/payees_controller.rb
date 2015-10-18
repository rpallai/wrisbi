class PayeesController < ApplicationController
  private
  before_filter :set_treasury, :only => [:index, :new]
  def set_treasury
    @treasury = Treasury.find(params[:treasury_id])
  end

  public

  # GET /payees
  # GET /payees.json
  def index
    @payees = @treasury.payees.all
    return if needs_deeply_concerned(@treasury)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @payees }
    end
  end

  # GET /payees/1
  # GET /payees/1.json
  def show
    @payee = Payee.find(params[:id])
    @treasury = @payee.treasury
    return if needs_deeply_concerned(@treasury)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @payee }
    end
  end

  # GET /payees/new
  # GET /payees/new.json
  def new
    @payee = @treasury.payees.build
    return if needs_deeply_concerned(@treasury)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @payee }
    end
  end

  # GET /payees/1/edit
  def edit
    @payee = Payee.find(params[:id])
    @treasury = @payee.treasury
    return if needs_deeply_concerned(@treasury)
    return if needs_treasury_supervisor @treasury unless @payee.transactions.empty?
  end

  # POST /payees
  # POST /payees.json
  def create
    @payee = Payee.new(payee_params)
    @treasury = @payee.treasury
    return if needs_deeply_concerned(@treasury)

    respond_to do |format|
      if @payee.save
        format.html { redirect_to treasury_payees_path(@treasury) }
        format.json { render json: @payee, status: :created, location: @payee }
      else
        format.html { render action: "new" }
        format.json { render json: { errors: @payee.errors }, status: :unprocessable_entity }
      end
    end
  end

  # PUT /payees/1
  # PUT /payees/1.json
  def update
    @payee = Payee.find(params[:id])
    @treasury = @payee.treasury
    return if needs_deeply_concerned(@treasury)
    return if needs_treasury_supervisor @treasury unless @payee.transactions.empty?

    respond_to do |format|
      if @payee.update_attributes(payee_params)
        format.html { redirect_to treasury_payees_path(@treasury) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: { errors: @payee.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /payees/1
  # DELETE /payees/1.json
  def destroy
    @payee = Payee.find(params[:id])
    @treasury = @payee.treasury
    return if needs_deeply_concerned(@treasury)
    return if needs_treasury_supervisor @treasury unless @payee.transactions.empty?
    @payee.destroy

    respond_to do |format|
      format.html { redirect_to treasury_payees_url(@treasury) }
      format.json { head :no_content }
    end
  end

  private
  def payee_params
    params.require(:payee).permit(:treasury_id, :name, :aliases)
  end
end
