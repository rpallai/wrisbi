# encoding: utf-8
module ViewHelper
  def print_sign(number)
    if number < 0
      'negative'
    elsif number > 0
      'positive'
    end
  end

  def account_to_classes(account)
    "p%d a%d" % [account.person.id, account.id]
  end

  def print_category(category, with_business = true)
    r = nil
    if category
      Rails.logger.silence do
        r = category.ancestors.push(category).map(&:name).join('/')
      end
      r << " [#{category.applied_business.name}]" if with_business and category.applied_business
    end
    r
  end

  def transaction_rowspan(transaction)
    1 + parties_of(transaction).length + parties_of(transaction).to_a.sum{|p| p.titles.length }
    #1 + transaction.titles.length + transaction.parties.length
  end

  def parties_of(transaction)
    # ha accounts/:id/transactions nezetben vagyunk, akkor csak az adott party erdekes,
    # maskepp a balance nem lesz franko
    if @account and @show_balance
      transaction.parties.find_all{|p| p.account == @account }
    else
      transaction.parties
    end
  end

  def link_account(account)
    link_to(account.person.name, [account.person, :operations])+'/'+
      link_to(account.name, url_with_time_window([account, :operations]))
  end

  def transaction_link_account(account)
    link_to(account.person.name, [account.person, :operations])+'/'+
      link_to(account.name, url_with_time_window([account, :transactions]))
  end

  def transactions_category_link(category)
    if @account
      [@account, category, :transactions]
    else
      [current_namespace, category, :transactions]
    end
  end

  def transactions_title_class_link(class_name)
    eval("#{current_namespace}_treasury_title_class_transactions_path(@treasury, class_name.demodulize.underscore)")
  end

  def get_title_class_name(name)
    (
      (current_namespace.classify + '::Title::' + name.classify).safe_constantize ||
      ('Title::' + name.classify).safe_constantize
    ).display_name
  end

  def time_dimension_as_text
    if params[:year]
      if params[:year].ends_with? 'ge'
        "az úr #{params[:year].to_i}-edik esztendejében és előtte"
      elsif params[:year].ends_with? 'le'
        "az úr #{params[:year].to_i}-edik esztendejében és utána"
      else
        "az úr #{params[:year].to_i}-edik esztendejében"
      end
    end
  end
end
