class BusinessesController < ApplicationController
  private
  before_filter :set_treasury, :only => [:index, :new]
  def set_treasury
    @treasury = Treasury.find(params[:treasury_id])
  end

  public

  # GET /businesses
  # GET /businesses.json
  def index
    @businesses = @treasury.businesses.all
    return if needs_deeply_concerned(@treasury)

    @page_title = '/businesses'
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @businesses }
    end
  end

  # GET /businesses/1
  # GET /businesses/1.json
  def show
    @business = Business.find(params[:id])
    @treasury = @business.treasury
    return if needs_deeply_concerned(@treasury)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @business }
    end
  end

  # GET /businesses/new
  # GET /businesses/new.json
  def new
    @business = @treasury.businesses.build
    return if needs_treasury_supervisor(@treasury)

    build_some_empty_shares
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @business }
    end
  end

  # GET /businesses/1/edit
  def edit
    @business = Business.find(params[:id])
    @treasury = @business.treasury
    return if needs_treasury_supervisor(@treasury)
    build_some_empty_shares
  end

  # POST /businesses
  # POST /businesses.json
  def create
    @business = Business.new(business_params)
    @treasury = @business.treasury
    return if needs_treasury_supervisor(@treasury)

    respond_to do |format|
      if @business.save
        format.html { redirect_to treasury_businesses_path(@treasury), notice: 'Business was successfully created.' }
        format.json { render json: @business, status: :created, location: @business }
      else
        build_some_empty_shares
        format.html { render action: "new" }
        format.json { render json: @business.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /businesses/1
  # PUT /businesses/1.json
  def update
    @business = Business.find(params[:id])
    @treasury = @business.treasury
    return if needs_treasury_supervisor(@treasury)

    respond_to do |format|
      if @business.update_attributes(business_params)
        format.html { redirect_to treasury_businesses_path(@treasury), notice: 'Business was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @business.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /businesses/1
  # DELETE /businesses/1.json
  def destroy
    @business = Business.find(params[:id])
    @treasury = @business.treasury
    return if needs_treasury_supervisor(@treasury)
    @business.destroy

    respond_to do |format|
      format.html { redirect_to treasury_businesses_path(@business.treasury) }
      format.json { head :no_content }
    end
  end

  private
  def build_some_empty_shares
    ([@business.treasury.people_with_share.count, 5].min - @business.shares.count).times do
      @business.shares.build
    end
  end

  def business_params
		params.require(:business).permit(:treasury_id, :name, :comment,
			shares_attributes: [ :id, :_destroy, :person_id, :share ])
  end
end
