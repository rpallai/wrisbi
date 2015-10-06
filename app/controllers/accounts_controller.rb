class AccountsController < ApplicationController
  private
  before_filter :set_person, :only => [:new]
  before_filter :set_model
  before_filter :alias_params, :only => [:create, :update]
  def set_person
    @person = Person.find(params[:person_id])
  end
  def set_model
    @model = params[:requirements][:class_name].constantize
  end
  def alias_params
    params[:account] = params[@model.model_name.singular.to_sym]
  end

  public

  # GET /accounts/new
  # GET /accounts/new.json
  def new
    @account = @model.new
    @account.person = @person
    @treasury = @account.treasury
    return if needs_treasury_supervisor(@treasury)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @account }
    end
  end

  # GET /accounts/1/edit
  def edit
    @account = Account.find(params[:id])
    @treasury = @account.treasury
    return if needs_treasury_supervisor(@treasury)
  end

  # POST /accounts
  # POST /accounts.json
  def create
    @account = @model.new(account_params)
    @treasury = @account.treasury
    return if needs_treasury_supervisor(@treasury)

    respond_to do |format|
      if @account.save
        format.html { redirect_to @treasury, notice: 'Account was successfully created.' }
        format.json { render json: @account, status: :created, location: @account }
      else
        format.html { render action: "new" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /accounts/1
  # PUT /accounts/1.json
  def update
    @account = Account.find(params[:id])
    @treasury = @account.treasury
    return if needs_treasury_supervisor(@treasury)

    respond_to do |format|
      if @account.update_attributes(account_params)
        format.html { redirect_to @treasury, notice: 'Account was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accounts/1
  # DELETE /accounts/1.json
  def destroy
    @account = @model.find(params[:id])
    @treasury = @account.treasury
    return if needs_treasury_supervisor(@treasury)
    @account.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :no_content }
    end
  end

  private
  def account_params
    params.require(@model.model_name.singular.to_sym).permit(
      :person_id, :name, :currency, :type_user, :hidden, :foreign_ids, :parent_id, :closed
    )
  end
end
