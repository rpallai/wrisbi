class ViewController < ApplicationController
  helper_method :get_permalink
  helper_method :url_with_time_dimension
  helper_method :page_limit

  #
  # ez majdnem ugyanugy nez ki mint a titles,
  # de az osszeg az account szempontjabol jelenik meg
  #
  def operations
    @page_title = ''
    if params[:account_id]
      @account = Account.find(params[:account_id])
      @treasury = @account.treasury
      unless @account.person.user == @current_user
        return if needs_deeply_concerned(@treasury)
        return if needs_treasury_supervisor(@treasury) if @account.hidden?
      end
      where_account_id = @account.id
      @date_field = @account.order_column
      @order = @account.order_column
      @page_title << '/' << view_context.print_account(@account)
    elsif params[:account_type_code]
      @treasury = Treasury.find(params[:treasury_id])
      return if needs_deeply_concerned(@treasury)
      accounts = @treasury.accounts.where(type_code: params[:account_type_code])
      accounts = accounts.where(subtype_code: params[:account_subtype_code]) if params[:account_subtype_code]
      #return if needs_treasury_supervisor(@treasury) if accounts.any?(&:hidden?)
      # az .ids nem mukodik, valami Rails bug
      where_account_id = accounts.pluck('accounts.id')
      @date_field = 'transactions.date'
      @order = @date_field
      @page_title << '/accounts:' << params[:account_type_code]
      @page_title << '|' << params[:account_subtype_code] if params[:account_subtype_code]
    elsif params[:person_id]
      @person = Person.find(params[:person_id])
      @treasury = @person.treasury
      unless @person.user == @current_user
        return if needs_deeply_concerned(@treasury)
      end
      accounts = @person.accounts_for_equity
      where_account_id = accounts.ids
      @date_field = 'transactions.date'
      @order = @date_field
      @page_title << '/' << @person.name
    else
      raise "WAT?"
    end

    operations = Operation.where(account_id: where_account_id).
      joins(:title => :transaction).
      group('titles.id').
      order(@order, 'transactions.id')
    if params[:category_id]
      operations = operations.joins(:title => :categories).where('categories.id = ?', params[:category_id])
    end
    @operations = operations.includes([:transaction, {:title => [{:operations => :person}, :categories]}]).
      # tobb szamla eseten a szumma az osszeg
      select("*,SUM(operations.amount) AS amount")
    # filters
    @page_title << '/operations'

    respond_to do |format|
      format.html do
        offset = calc_offset_by_param_page
        @operations = @operations.limit(page_limit).offset(offset)

        rows = Operation.connection.exec_query("
          SELECT date, balance
          FROM (
            SELECT date,
                   (@balance := @balance + amount) - amount AS balance,
                   @rn := @rn + 1 AS rn
            FROM    (#{operations.select("#{@date_field} AS date, SUM(operations.amount) AS amount").to_sql}) original_view
            JOIN    (SELECT @rn := 0, @balance := 0) i
            ) counted
          WHERE (rn - 1) MOD #{page_limit} IN (0,#{page_limit - 1})
        ").rows
        if rows.length.odd?
          r = operations.select("#{@date_field} AS date, 0 AS balance").last
          rows << [r[:date], r[:balance]]
        end
        @intervals = rows.each_slice(2)

        @this_interval = @intervals.to_a[params[:page].to_i || 0] || ['']
      end
      format.csv {
				require 'csv'
				csv = CSV.generate do |l|
					l << ['date', 'category/peer', 'amount', 'balance', 'comment']
					balance = 0
					@operations.each{|operation|
            # XXX
						if operation.title.is_a? Title::Deal and operation.title.category
							cat = operation.title.category.ancestors.push(operation.title.category).map(&:name).join('/')
						elsif operation.title.is_a? Title::Transfer
							other_operation = operation.type_code == Title::Transfer::Left ? operation.title.right : operation.title.left
							cat = other_operation.person.name
						else
							cat = nil
						end
						l << [
							operation.transaction.date.strftime("%Y-%m-%d, %a"),
							cat,
							operation.amount,
							balance += operation.amount,
							operation.title.comment
						]
					}
				end
				send_data csv,
					:type => 'text/csv; charset=utf-8; header=present',
					:disposition => "attachment; filename=#{@account.person.name}_#{@account.name}-#{Date.today.to_s(:db)}.csv"
      }
      format.json { render json: @account }
    end
  end

  def titles
    @page_title = ''
    if params[:category_id]
      @category = Category.find(params[:category_id])
      @treasury = @category.treasury
      return if needs_deeply_concerned(@treasury)
      titles = @category.titles_r
      @show_balance = true
      @page_title << '/' << view_context.print_category(@category, false)
    elsif params[:account_id]
      @account = Account.find(params[:account_id])
      @treasury = @account.treasury
      return if needs_deeply_concerned(@treasury)
      titles = @account.titles
    elsif params[:treasury_id]
      @treasury = Treasury.find(params[:treasury_id])
      return if needs_deeply_concerned(@treasury)
      if params[:filter] == "no_category"
        titles = @treasury.titles.where("titles.type != 'Title::TransferHead'").
          joins(
            "LEFT OUTER JOIN `categories_titles` ON `categories_titles`.`title_id` = `titles`.`id` "+
            "LEFT OUTER JOIN `categories` ON `categories`.`id` = `categories_titles`.`category_id`"
          ).where(categories: { id: nil })
        @page_title << '/' << "no_category"
      else
        titles = @treasury.titles
      end
    end

    @titles = titles.includes(
			:categories, :transaction,
      :operations => { :account => :person },
      :party => { :account => :person }
		)

    case params[:sort]
    when 'title'
      @date_field = 'titles.date'
      @order = @date_field+' DESC'
    when 'transaction'
      @date_field = 'transactions.date'
      @order = @date_field+' DESC'
    else
      # XXX ez a cegnel lehet nem jo
      if params[:category_id]
        @date_field = 'transactions.date'
        @order = @date_field+' DESC'
      else
        @date_field = 'titles.date'
        @order = @date_field+' DESC'
      end
    end
    @titles = @titles.order(@order)

    offset = calc_offset_by_param_page
    @titles = @titles.limit(page_limit).offset(offset)

    rows = Title.connection.exec_query("
      SELECT date, balance
      FROM (
        SELECT date,
               (@balance := @balance + amount) - amount AS balance,
               @rn := @rn + 1 AS rn
        FROM    (#{titles.joins(:transaction).order(@order).select("#{@date_field} AS date, titles.amount").to_sql}) original_view
        JOIN    (SELECT @rn := 0, @balance := 0) i
        ) counted
      WHERE (rn - 1) MOD #{page_limit} IN (0,#{page_limit - 1})
    ").rows
    if rows.length.odd?
      r = titles.joins(:transaction).order(@order).select("#{@date_field} AS date, 0 AS balance").last
      rows << [r[:date], r[:balance]]
    end
    @intervals = rows.each_slice(2)

    @this_interval = @intervals.to_a[params[:page].to_i || 0] || ['']

    @page_title << '/titles'
    #XXX titles_by_month: .order('applied_business_id')
    # filters
#    if params[:filter_year]
#      start_date = Date.parse("%d-01-01" % params[:filter_year])
#      end_date = Date.parse("%d-12-31" % params[:filter_year])
#      @titles = @titles.where("date BETWEEN ? AND ?", start_date, end_date)
#    else
#      d = @treasury.transactions.order('date').last.date - 60
#      f = "%d-%d-01" % [d.year, d.month]
#      @titles = @titles #.where("date >= ?", f)
#    end
    # XXX ez head-re szur; mikor hasznaljuk?
#    if params[:account_id] and (params[:category_id] or  params[:treasury_id])
#      @titles = @titles.where('transactions.account_id' => params[:account_id])
#    end
    #@titles = @titles.limit(20)
    respond_to do |format|
      format.html
    end
  end

  def titles_by_month
    titles
    level1 = @titles.group_by{|m| m.transaction.date.strftime("%Y-%m") }
    @level2 = Hash[level1.map{|key,titles|
        [key, titles.group_by{|m| {label: m.class.display_name, html_class: m.class.name.demodulize }} ]
    }]
    #logger.debug "view_paths: #{view_paths.inspect}"
    prepend_view_path Rails.root.to_s+'/app/views/view/titles_by_month'
  end

  def transactions
    @page_title = ''
    if params[:account_id]
      @account = Account.find(params[:account_id])
      @treasury = @account.treasury
      return if needs_deeply_concerned(@treasury)
      @date_field = "transactions.date"
      @order = @date_field
      @page_title << '/' << view_context.print_account(@account)
      if params[:category_id]
        @category = Category.find(params[:category_id])
        transactions = Transaction.joins(:parties => { :titles => :categories }).
          where('parties.account_id = ?', @account).
          where('categories.id = ?', @category)
        @page_title << "/" << view_context.print_category(@category, false)
      else
        transactions = Transaction.joins(:parties).where('parties.account_id = ?', @account)
        @show_balance = true
      end
    elsif params[:treasury_id]
      @treasury = Treasury.find(params[:treasury_id])
      return if needs_deeply_concerned(@treasury)
      transactions = @treasury.transactions
      @date_field = "transactions.date"
      @order = @date_field+" DESC"
    end
    @page_title << '/transactions'
    if params[:unacked]
      transactions = transactions.where(supervised: false)
      @page_title << '/unacked'
    end
    @transactions = transactions.includes(
      :titles,
			:parties => {
        :account => :person,
        :titles => [:categories, :operations => { :account => :person }]
      },
    )
    case params[:sort]
    when 'last_touch'
      @date_field = "transactions.updated_at"
      @order = @date_field+" DESC"
    end
    @transactions = @transactions.order(@order)

    unless @order == "transactions.updated_at DESC"
      @latest_updated_transaction = transactions.order('updated_at DESC').first
    end

    unless @show_balance
      rows = Transaction.connection.exec_query("
        SELECT date
        FROM (
          SELECT date,
                 @rn := @rn + 1 AS rn
          FROM    (#{transactions.order(@order).select("#{@date_field} AS date").to_sql}) original_view
          JOIN    (SELECT @rn := 0) i
          ) counted
        WHERE (rn - 1) MOD #{page_limit} IN (0,#{page_limit - 1})
      ").rows
    else
      rows = Transaction.connection.exec_query("
        SELECT date, balance
        FROM (
          SELECT date,
                 (@balance := @balance + amount) - amount AS balance,
                 @rn := @rn + 1 AS rn
          FROM    (#{transactions.order(@order).select("#{@date_field} AS date, parties.amount").to_sql}) original_view
          JOIN    (SELECT @rn := 0, @balance := 0) i
          ) counted
        WHERE (rn - 1) MOD #{page_limit} IN (0,#{page_limit - 1})
      ").rows
    end
    if rows.length.odd?
      r = transactions.order(@order).select("#{@date_field} AS date, 0 AS balance").last
      rows << [r[:date], r[:balance]]
    end
    @intervals = rows.each_slice(2)

    @this_interval = @intervals.to_a[params[:page].to_i || 0] || ['']

    offset = calc_offset_by_param_page
    # XXX lehetne ugy, hogy idoablakot ad meg a hivatkozo es konvertaljuk
    #offset = calc_offset_by_param_date
    @transactions = @transactions.limit(page_limit).offset(offset)

    respond_to do |format|
      format.html do
        unless mobile_device?
          render
        else
          render action: 'transactions_mobile'
        end
      end
    end
  ensure
    Treasury.reset_data_scope
  end

  private
  def get_permalink(opts = {})
    {
      sort: params[:sort],
      page: params[:page],
      per_page: params[:per_page],
      account_type_code: params[:account_type_code],
      account_subtype_code: params[:account_subtype_code],
    }.update(opts)
  end

  def url_with_time_dimension(args)
    polymorphic_url(args, {year: params[:year]})
  end

  def calc_offset_by_param_page
    if params[:page]
      params[:page].to_i * page_limit
    else
      0
    end
  end

  def page_limit
    if params[:per_page]
      params[:per_page].to_i
    else
      50
    end
  end
end
