module ApplicationHelper
  def prepend_options_wzero(options)
    options.unshift(['', nil])
  end

  def collect_name_and_id(objs)
    objs.collect{|obj| [obj.respond_to?(:full_name) ? obj.full_name : obj.name, obj.id] }
  end

  def print_amount(amount)
    number_to_currency(amount, :precision => 0, :unit => '', :delimiter => '.')
  end

  def current_namespace
    params[:controller].split("/").first
  end

  def date_for_sort(date)
    date or Date.parse("1980-01-01")
  end
  def balance_for_sort(balance)
    balance or 0
  end
end
