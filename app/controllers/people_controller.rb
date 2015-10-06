class PeopleController < ApplicationController
  private
  before_filter :set_treasury, :only => [:new]
  before_filter :set_model, :except => :index
  before_filter :alias_params, :only => [:create, :update]
  def set_treasury
    @treasury = Treasury.find(params[:treasury_id])
  end
  def set_model
    @model = params[:requirements][:class_name].constantize
  end
  def alias_params
    params[:person] = params[@model.model_name.singular.to_sym]
  end

  public

  # GET /people/new
  # GET /people/new.json
  def new
    @person = @model.new
    @person.treasury = @treasury
    return if needs_treasury_supervisor(@person.treasury)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @person }
    end
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
    @treasury = @person.treasury
    return if needs_treasury_supervisor(@treasury)
  end

  # POST /people
  # POST /people.json
  def create
    @person = @model.new(person_params)
    @treasury = @person.treasury
    return if needs_treasury_supervisor(@treasury)

    respond_to do |format|
      if @person.save
        format.html { redirect_to @treasury, notice: 'Person was successfully created.' }
        format.json { render json: @person, status: :created, location: @person }
      else
        format.html { render action: "new" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.json
  def update
    @person = Person.find(params[:id])
    @treasury = @person.treasury
    return if needs_treasury_supervisor(@treasury)

    respond_to do |format|
      if @person.update_attributes(person_params)
        format.html { redirect_to @treasury }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @person = Person.find(params[:id])
    @treasury = @person.treasury
    return if needs_treasury_supervisor(@treasury)
    @person.destroy

    respond_to do |format|
      format.html { redirect_to @treasury }
      format.json { head :no_content }
    end
  end

  private
  def person_params
    params.require(@model.model_name.singular.to_sym).permit(
      :treasury_id, :name, :user_id, :type_code, :restricted
    )
  end
end
