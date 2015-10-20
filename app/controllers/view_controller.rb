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
      account_ids = @account.id
      @date_field = @account.order_column
      @page_title << '/' << view_context.print_account(@account)
    elsif params[:account_type_code]
      @treasury = Treasury.find(params[:treasury_id])
      return if needs_deeply_concerned(@treasury)
      accounts = @treasury.accounts.where(type_code: params[:account_type_code])
      accounts = accounts.where(subtype_code: params[:account_subtype_code]) if params[:account_subtype_code]
      #return if needs_treasury_supervisor(@treasury) if accounts.any?(&:hidden?)
      # az .ids nem mukodik, valami Rails bug
      account_ids = accounts.pluck('accounts.id')
      @date_field = 'transactions.date'
      @page_title << '/accounts:' << params[:account_type_code]
      @page_title << '|' << params[:account_subtype_code] if params[:account_subtype_code]
    elsif params[:person_id]
      @person = Person.find(params[:person_id])
      @treasury = @person.treasury
      unless @person.user == @current_user
        return if needs_deeply_concerned(@treasury)
      end
      accounts = @person.accounts_for_equity
      account_ids = accounts.ids
      @date_field = 'transactions.date'
      @page_title << '/' << @person.name
    else
      raise "WAT?"
    end

    @order = @date_field
    @order << " DESC" if @backward

    operations = Operation.where(account_id: account_ids).
      joins(:title => :transaction).
      group('titles.id').
      order(@order, 'transactions.id').
      select("SUM(operations.amount) AS amount")
    if params[:category_id]
      operations = operations.joins(:title => :categories).where('categories.id = ?', params[:category_id])
    end
    # tobb szamla eseten a szumma az osszeg
    @operations = operations.includes([:transaction, {:title => [{:operations => :person}, :categories]}]).
      select('operations.title_id', 'operations.account_id')

    @page_title << '/operations'

    respond_to do |format|
      format.html {
        operations = operations.select("#{@date_field} AS date")
        if @backward
          pages_query = Operation.scoped.
            select("MAX(date) AS date_start, MIN(date) AS date_end, COUNT(*) AS c").order('date DESC')
        else
          pages_query = Operation.scoped.
            select("MIN(date) AS date_start, MAX(date) AS date_end, COUNT(*) AS c").order('date ASC')
        end

        case params[:per_page]
        when "week" then pages_query = pages_query.group("YEARWEEK(date, 1)")
        when "month" then pages_query = pages_query.group("YEAR(date),MONTH(date)")
        when "quarter" then pages_query = pages_query.group("YEAR(date),QUARTER(date)")
        when "year" then pages_query = pages_query.group("YEAR(date)")
        else pages_query = pages_query.group("FLOOR(@rn := @rn + 1 / #{page_limit + 1})").joins("JOIN (SELECT @rn := 0) i")
        end
        # itt pontosan ugyanaz a sorrend kell a lapozoban es a lapon, maskepp az egyenleg elcsuszik
        if continuous_paging?
          operations = operations.order(@order).order(:id)
        end

        pages_query = pages_query.select("SUM(amount) AS sum_amount")
        pages_query = pages_query.from("(#{operations.to_sql}) AS all_operations")

        with_balance_query = Operation.scoped.
          joins('JOIN (SELECT @balance := 0) i').
          select("date_start, date_end, (@balance := @balance + sum_amount) - sum_amount AS balance, c").
          from("(#{pages_query.to_sql}) AS pages")
        query = with_balance_query

        rows = Transaction.connection.exec_query(query.to_sql).rows

        @intervals = []
        rows.each{|row| @intervals << [[row[0], row[2]], [row[1]]] }

        @this_interval = @intervals.to_a[params[:page].to_i || 0] || ['']

        if continuous_paging?
          offset = calc_offset_by_param_page
          # XXX lehetne ugy, hogy idoablakot ad meg a hivatkozo es konvertaljuk
          #offset = calc_offset_by_param_date
          @operations = @operations.limit(page_limit).offset(offset)
        else
          if @backward
            @operations = @operations.where("#{@date_field} BETWEEN ? AND ?", @this_interval[1][0], @this_interval[0][0])
          else
            @operations = @operations.where("#{@date_field} BETWEEN ? AND ?", @this_interval[0][0], @this_interval[1][0])
          end
        end
      }
      format.csv {
        require 'csv'
        csv = CSV.generate do |l|
          l << ['date', 'category/peer', 'amount', 'balance', 'comment']
          balance = 0
          @operations.each{|operation|
            # XXX ronda hack
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
        # XXX bena hack
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
    case params[:sort]
    when 'title'
      @date_field = 'titles.date'
      @backward = true
    when 'transaction'
      @date_field = 'transactions.date'
      @backward = true
    else
      if params[:category_id]
        @date_field = 'transactions.date'
        @backward = true
      else
        @date_field = 'titles.date'
        @backward = true
      end
    end

    @order = @date_field.dup
    @order << ' DESC' if @backward

    @titles = titles.includes(
      :categories, :transaction,
      :operations => { :account => :person },
      :party => { :account => :person }
    ).order(@order)

    titles = titles.joins(:transaction)

    @page_title << '/titles'
    #XXX titles_by_month: .order('applied_business_id')
    # XXX ez head-re szur; mikor hasznaljuk?
    #    if params[:account_id] and (params[:category_id] or  params[:treasury_id])
    #      @titles = @titles.where('transactions.account_id' => params[:account_id])
    #    end

    respond_to do |format|
      format.html {
        titles = titles.select("#{@date_field} AS date, titles.amount")
        if @backward
          pages_query = Title.scoped.
            select("MAX(date) AS date_start, MIN(date) AS date_end, COUNT(*) AS c").order('date DESC')
        else
          pages_query = Title.scoped.
            select("MIN(date) AS date_start, MAX(date) AS date_end, COUNT(*) AS c").order('date ASC')
        end

        case params[:per_page]
        when "week" then pages_query = pages_query.group("YEARWEEK(date, 1)")
        when "month" then pages_query = pages_query.group("YEAR(date),MONTH(date)")
        when "quarter" then pages_query = pages_query.group("YEAR(date),QUARTER(date)")
        when "year" then pages_query = pages_query.group("YEAR(date)")
        else pages_query = pages_query.group("FLOOR(@rn := @rn + 1 / #{page_limit + 1})").joins("JOIN (SELECT @rn := 0) i")
        end
        # itt pontosan ugyanaz a sorrend kell a lapozoban es a lapon, maskepp az egyenleg elcsuszik
        if continuous_paging?
          titles = titles.order(@order).order(:id)
        end

        pages_query = pages_query.select("SUM(amount) AS sum_amount")
        pages_query = pages_query.from("(#{titles.to_sql}) AS all_titles")

        with_balance_query = Title.scoped.
          joins('JOIN (SELECT @balance := 0) i').
          select("date_start, date_end, (@balance := @balance + sum_amount) - sum_amount AS balance, c").
          from("(#{pages_query.to_sql}) AS pages")
        query = with_balance_query

        rows = Transaction.connection.exec_query(query.to_sql).rows

        @intervals = []
        rows.each{|row| @intervals << [[row[0], row[2]], [row[1]]] }

        @this_interval = @intervals.to_a[params[:page].to_i || 0] || ['']

        if continuous_paging?
          offset = calc_offset_by_param_page
          # XXX lehetne ugy, hogy idoablakot ad meg a hivatkozo es konvertaljuk
          #offset = calc_offset_by_param_date
          @titles = @titles.limit(page_limit).offset(offset)
        else
          if @backward
            @titles = @titles.where("#{@date_field} BETWEEN ? AND ?", @this_interval[1][0], @this_interval[0][0])
          else
            @titles = @titles.where("#{@date_field} BETWEEN ? AND ?", @this_interval[0][0], @this_interval[1][0])
          end
        end
      }
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
      @backward = true
    end
    @page_title << '/transactions'
    if params[:unacked]
      transactions = transactions.where(supervised: false)
      @page_title << '/unacked'
    end
    if params[:sort] == 'last_touch'
      @date_field = "transactions.updated_at"
      @backward = true
      @show_balance = false
    else
      @latest_updated_transaction = transactions.order('updated_at DESC').order(:id).first
    end

    @order = @date_field.dup
    @order << " DESC" if @backward

    @transactions = transactions.includes(
      :titles,
      :parties => {
        :account => :person,
        :titles => [:categories, :operations => { :account => :person }]
      },
    ).order(@order).order(:id)

    transactions = transactions.select("#{@date_field} AS date")
    if @backward
      pages_query = Transaction.scoped.
        select("MAX(date) AS date_start, MIN(date) AS date_end, COUNT(*) AS c").order('date DESC')
    else
      pages_query = Transaction.scoped.
        select("MIN(date) AS date_start, MAX(date) AS date_end, COUNT(*) AS c").order('date ASC')
    end

    case params[:per_page]
    when "week" then pages_query = pages_query.group("YEARWEEK(date, 1)")
    when "month" then pages_query = pages_query.group("YEAR(date),MONTH(date)")
    when "quarter" then pages_query = pages_query.group("YEAR(date),QUARTER(date)")
    when "year" then pages_query = pages_query.group("YEAR(date)")
    else pages_query = pages_query.group("FLOOR(@rn := @rn + 1 / #{page_limit + 1})").joins("JOIN (SELECT @rn := 0) i")
    end
    # itt pontosan ugyanaz a sorrend kell a lapozoban es a lapon, maskepp az egyenleg elcsuszik
    if continuous_paging?
      transactions = transactions.order(@order).order(:id)
    end

    if @show_balance
      transactions = transactions.select('parties.amount')
      pages_query = pages_query.select("SUM(amount) AS sum_amount")
    end
    pages_query = pages_query.from("(#{transactions.to_sql}) AS all_transactions")
    if @show_balance
      with_balance_query = Transaction.scoped.
        joins('JOIN (SELECT @balance := 0) i').
        select("date_start, date_end, (@balance := @balance + sum_amount) - sum_amount AS balance, c").
        from("(#{pages_query.to_sql}) AS pages")
      query = with_balance_query
    else
      query = pages_query
    end

    rows = Transaction.connection.exec_query(query.to_sql).rows

    @intervals = []
    rows.each{|row| @intervals << [[row[0], row[2]], [row[1]]] }

    @this_interval = @intervals.to_a[params[:page].to_i || 0] || ['']

    if continuous_paging?
      offset = calc_offset_by_param_page
      # XXX lehetne ugy, hogy idoablakot ad meg a hivatkozo es konvertaljuk
      #offset = calc_offset_by_param_date
      @transactions = @transactions.limit(page_limit).offset(offset)
    else
      if @backward
        @transactions = @transactions.where("#{@date_field} BETWEEN ? AND ?", @this_interval[1][0], @this_interval[0][0])
      else
        @transactions = @transactions.where("#{@date_field} BETWEEN ? AND ?", @this_interval[0][0], @this_interval[1][0])
      end
    end

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
    if params[:per_page].nil?
      50
    elsif params[:per_page].to_i.nonzero?
      params[:per_page].to_i
    else
      params[:per_page]
    end
  end

  def discrete_paging?
    not params[:per_page].nil? and params[:per_page].to_i.zero?
  end
  def continuous_paging?
    params[:per_page].nil? or params[:per_page].to_i.nonzero?
  end
end
