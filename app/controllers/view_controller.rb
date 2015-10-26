class ViewController < ApplicationController
  helper_method :get_permalink
  helper_method :url_with_time_window
  helper_method :page_limit
  helper_method :discrete_paging?, :continuous_paging?

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
      order(@order, 'titles.id').
      select("SUM(operations.amount) AS amount")
    if params[:category_id]
      operations = operations.joins(:title => :categories).where('categories.id = ?', params[:category_id])
    end
    operations = apply_comment_search(operations)
    # tobb szamla eseten a szumma az osszeg
    @operations = operations.includes([:transaction, {:title => [{:operations => :person}, :categories]}]).
      select('operations.title_id', 'operations.account_id')

    @page_title << '/operations'

    respond_to do |format|
      format.html {
        @show_balance = true
        paginate(operations)
        @operations = scoping_current_page(@operations)
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
    titles = apply_comment_search(titles)
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
    ).order(@order).order(:id)

    titles = titles.joins(:transaction)

    @page_title << '/titles'
    #XXX titles_by_month: .order('applied_business_id')
    # XXX ez head-re szur; mikor hasznaljuk?
    #    if params[:account_id] and (params[:category_id] or  params[:treasury_id])
    #      @titles = @titles.where('transactions.account_id' => params[:account_id])
    #    end

    respond_to do |format|
      format.html {
        titles = titles.select('titles.amount') if @show_balance
        paginate(titles)
        @titles = scoping_current_page(@titles)
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
        if params[:s] and not params[:s].empty?
          transactions = Transaction.joins(:parties => :titles)
        else
          transactions = Transaction.joins(:parties)
        end
        transactions = transactions.where('parties.account_id = ?', @account)
        @show_balance = true
      end
    elsif params[:treasury_id]
      @treasury = Treasury.find(params[:treasury_id])
      return if needs_deeply_concerned(@treasury)
      transactions = @treasury.transactions
      transactions = transactions.joins(:titles) if params[:s] and not params[:s].empty?
      @date_field = "transactions.date"
      @backward = true
    end
    @page_title << '/transactions'
    if params[:unacked]
      transactions = transactions.where(supervised: false)
      @page_title << '/unacked'
    end
    transactions = apply_comment_search(transactions)
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

    respond_to do |format|
      format.html {
        transactions = transactions.select('parties.amount') if @show_balance
        paginate(transactions)
        @transactions = scoping_current_page(@transactions)

        unless mobile_device?
          render
        else
          render action: 'transactions_mobile'
        end
      }
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

  def url_with_time_window(args)
    if discrete_paging?
      polymorphic_url(args,
        sort: params[:sort],
        page: params[:page],
        per_page: params[:per_page],
      )
    else
      polymorphic_url(args)
    end
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

  def paginate(original_scope)
    pages_scope = Transaction.all

    case params[:per_page]
    when "week"
      pages_scope = pages_scope.group("YEARWEEK(date, 1)").select("YEARWEEK(date, 1) AS page_key")
    when "month"
      pages_scope = pages_scope.group("YEAR(date),MONTH(date)").select("CONCAT_WS('-',YEAR(date),MONTH(date)) AS page_key")
    when "quarter"
      pages_scope = pages_scope.group("YEAR(date),QUARTER(date)").select("CONCAT_WS('-',YEAR(date),QUARTER(date)) AS page_key")
    when "year"
      pages_scope = pages_scope.group("YEAR(date)").select("YEAR(date) AS page_key")
    else
      pages_scope = pages_scope.group("FLOOR(@rn := @rn + 1 / #{page_limit + 1})").joins("JOIN (SELECT @rn := 0) i").
        select("CAST(CAST(@rn AS DECIMAL) AS CHAR) AS page_key")
    end

    if @backward
      pages_scope = pages_scope.select("MAX(date) AS date_start, MIN(date) AS date_end, COUNT(*) AS c").order('date DESC')
    else
      pages_scope = pages_scope.select("MIN(date) AS date_start, MAX(date) AS date_end, COUNT(*) AS c").order('date ASC')
    end

    original_scope = original_scope.select("#{@date_field} AS date")
    # itt pontosan ugyanaz a sorrend kell a lapozoban es a lapon, maskepp az egyenleg elcsuszik
    if continuous_paging?
      original_scope = original_scope.order(@order).order(:id)
    end

    if @show_balance
      pages_scope = pages_scope.select("SUM(amount) AS sum_amount")
    end
    pages_scope = pages_scope.from("(#{original_scope.to_sql}) AS original_scope")
    if @show_balance
      with_balance_query = Transaction.all.
        joins('JOIN (SELECT @balance := 0) i').
        select("page_key, date_start, date_end, (@balance := @balance + sum_amount) - sum_amount AS balance, c").
        from("(#{pages_scope.to_sql}) AS pages")
      query = with_balance_query
    else
      query = pages_scope
    end

    rows = Transaction.connection.exec_query(query.to_sql).rows

    @pages = Hash.new
    rows.each{|row| @pages[row[0].to_s] = {start_date: row[1], start_balance: row[3], end_date: row[2]} }

    @current_page = @pages[params[:page]] || @pages[@pages.keys.first]
  end

  def scoping_current_page(original_scope)
    if continuous_paging?
      offset = calc_offset_by_param_page
      # XXX lehetne ugy, hogy idoablakot ad meg a hivatkozo es konvertaljuk
      #offset = calc_offset_by_param_date
      original_scope.limit(page_limit).offset(offset)
    else
      if @backward
        original_scope.where("#{@date_field} BETWEEN ? AND ?", @current_page[:end_date], @current_page[:start_date])
      else
        original_scope.where("#{@date_field} BETWEEN ? AND ?", @current_page[:start_date], @current_page[:end_date])
      end
    end
  end

  def apply_comment_search(original_scope)
    if params[:s] and not params[:s].empty?
      original_scope = original_scope.where("CONCAT(transactions.comment, titles.comment) LIKE ?",
        "%" << params[:s] << "%")
      @page_title << '/search'
    end
    return original_scope
  end
end
