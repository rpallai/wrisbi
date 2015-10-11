# encoding: utf-8
class TransactionsController < ApplicationController
  helper_method :accounts_for_transaction

  before_filter :set_treasury, :only => [:index, :index_unacked, :new]
  def set_treasury
    @treasury = Treasury.find(params[:treasury_id])
  end

  # GET /transactions/new
  # GET /transactions/new.json
  def new
    params.permit!
    @transaction = @treasury.transactions.build(params[:p] || {})
    @transaction.parties.build unless params[:p]
    return if needs_deeply_concerned(@treasury)

    @transaction.date = @treasury.transactions.order(:updated_at).last.date unless params[:p] rescue nil

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  # ez olyan mint a new, csak egy meglevo tranzakciot klonoz
  def template_by_category
    @transaction = Transaction.joins(:parties => {:titles => :categories}).
      where("categories.id = ?", params[:id]).order(:updated_at).last
    as_template
  end
  def as_template
    @transaction ||= Transaction.find(params[:id])
    @treasury = @transaction.treasury
    return if needs_deeply_concerned(@treasury)
    orig_transaction = @transaction
    @transaction = @transaction.dup
    @transaction.comment = nil
    orig_transaction.parties.each do |party|
      @transaction.parties << party.dup
      party.titles.each do |title|
        @transaction.parties.last.titles << title.dup
        @transaction.parties.last.titles.last.categories = title.categories
        @transaction.parties.last.titles.last.comment = nil
      end
    end
    respond_to do |format|
      format.html { render 'new' }
    end
  end
  def new_build_new_party
    @transaction = Transaction.new(transaction_params)
    build_new_party
  end
  def new_build_new_title
    @transaction = Transaction.new(transaction_params)
    build_new_title
    respond_to do |format|
      format.html { render action: "new" }
    end
  end
  def new_copy_title
    @transaction = Transaction.new(transaction_params)
    copy_title
    respond_to do |format|
      format.html { render action: "new" }
    end
  end
  def new_refresh
    @transaction = Transaction.new(transaction_params)
    @treasury = @transaction.treasury
    respond_to do |format|
      format.html { render action: @transaction.new_record?? "new" : "edit" }
    end
  end

  # GET /transactions/1/edit
  def edit
    @transaction = Transaction.find(params[:id])
    @treasury = @transaction.treasury
  end
  def edit_build_new_party
    @transaction = Transaction.find(params[:id])
    @transaction.assign_attributes(transaction_params)
    build_new_party
  end
  def edit_build_new_title
    @transaction = Transaction.find(params[:id])
    @transaction.assign_attributes(transaction_params)
    build_new_title
    respond_to do |format|
      format.html { render action: "edit" }
    end
  end
  def edit_copy_title
    @transaction = Transaction.find(params[:id])
    @transaction.assign_attributes(transaction_params)
    copy_title
    respond_to do |format|
      format.html { render action: "edit" }
    end
  end
  def edit_refresh
    @transaction = Transaction.find(params[:id])
    @transaction.assign_attributes(transaction_params)
    @treasury = @transaction.treasury
    respond_to do |format|
      format.html { render action: @transaction.new_record?? "new" : "edit" }
    end
  end

  # POST /transactions
  # POST /transactions.json
  def create
    @transaction = Transaction.new(transaction_params)
    @treasury = @transaction.treasury
    return if needs_deeply_concerned(@treasury)
    @transaction.supervised = @treasury.supervisors.include?(@current_user) ? true : false
    @transaction.user = @current_user

    respond_to do |format|
      if @transaction.save
        if params[:iframe]
          format.html { render text: "created" }
        else
          format.html { redirect_to [@treasury, :transactions], notice: 'Transaction was successfully created.' }
        end
        format.json { render json: @transaction, status: :created, location: @transaction }
      else
        format.html { render action: "new" }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /transactions/1
  # PUT /transactions/1.json
  def update
    @transaction = Transaction.find(params[:id])
    @transaction.assign_attributes(transaction_params)
    @treasury = @transaction.treasury
    return if needs_deeply_concerned(@treasury)
    if @transaction.supervised? or @transaction.user != @current_user
      return if needs_treasury_supervisor(@treasury)
    end
    @transaction.supervised = @treasury.supervisors.include?(@current_user) ? true : false
    @transaction.user = @current_user

    respond_to do |format|
      if @transaction.save
        if params[:iframe]
          format.html { render text: "updated" }
        else
          format.html { redirect_to [@treasury, :transactions], notice: 'Transaction was successfully updated.' }
        end
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy
    @transaction = Transaction.find(params[:id])
    @treasury = @transaction.treasury
    if @transaction.supervised? or @transaction.user != @current_user
      return if needs_treasury_supervisor(@treasury)
    end
    @transaction.destroy

    respond_to do |format|
      if params[:iframe]
        format.html { render text: "destroyed" }
      else
        format.html { redirect_to :back }
      end
      format.json { head :no_content }
    end
  end

  def do_ack
    @transaction = Transaction.find(params[:id])
    @treasury = @transaction.treasury
    return if needs_treasury_supervisor(@treasury)
    @transaction.update_column(:supervised, true)
    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :no_content }
    end
  end

  private
  def transaction_params
    params.require(:transaction).permit(transaction_params_permitted)
  end

  def transaction_params_permitted
    [
      :treasury_id, :date, :comment, :invert,
      parties_attributes: [
        :id, :_destroy, :account_id, :amount,
        titles_attributes: [
          :id, :_destroy,
          :type, :date, :comment, :amount,
          :new_category_ids => [],
        ],
      ]
    ]
  end

  def build_new_party
    @treasury = @transaction.treasury
    @transaction.parties.build
    respond_to do |format|
      format.html { render action: @transaction.new_record?? "new" : "edit" }
    end
  end

  def build_new_title
    @treasury = @transaction.treasury
    params.permit!
    party_idx = params[:party_idx].to_i
    party = @transaction.parties[party_idx]
    party.titles.build(params[:new_title_attributes])
    @new_title = @transaction.parties[party_idx].titles.last
  end

  def copy_title
    @treasury = @transaction.treasury
    params.permit!
    party_idx = params[:party_idx].to_i
    party = @transaction.parties[party_idx]
    title_idx = params[:title_idx].to_i
    @source_title = party.titles[title_idx]
    # build
    @new_title = party.titles.build(params[:new_title_attributes])
    # copy
    # a kategoriat itt nem masoljuk, hiszen nagy valoszinuseggel nem fog megegyezni
    # szamlaknal a kelt, a komment es az AFA jo ha masolodik
    # az osszeg masolasnal szinten igen kis valoszinuseggel kell hogy megegyezzen, tipikusan split kell
    attributes = @source_title.attributes
    attributes.delete('type')
    attributes.delete('amount')
    @new_title.assign_attributes(attributes)
    # deploy
    if params[:replace]
      # masoljuk a kategoriat is
      if @source_title.new_record?
        party.titles.delete(@new_title)
        party.titles[title_idx] = @new_title
        # XXX category_ids masolas nelkul is atveszi a kategoriakat, miert?
      else
        @source_title.mark_for_destruction()
        # a form ebbe post-olja be az aktualis ertekeket, a categories csak az adatbazis allapotat mutatja
        @new_title.category_ids = @source_title.category_ids
      end
      @new_title.amount = @source_title.amount
    end
  end

  def accounts_for_transaction
    view_context.prepend_options_wzero(view_context.collect_name_and_id(@treasury.accounts))
  end
end
