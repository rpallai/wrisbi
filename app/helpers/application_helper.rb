module ApplicationHelper
  #
  # Egy <ol> tag-ben kirajzolja a fat
  #
  def traverse(node, stack = "", &block)
    node.each {|k, v|
      stack << "<li>"
      stack << capture do
        yield(k)
      end
      unless v.empty?
        stack << "<ol>"
        traverse(v, stack, &block)
        stack << "</ol>"
      end
      stack << "</li>"
    }
    stack
  end

  def traverse2(node, stack = "", depth = 0, &block)
    depth += 1
    node.each {|k, v|
      stack << capture do
        yield(k, depth) || ''
      end
      traverse2(v, stack, depth, &block) unless v.empty?
    }
    stack
  end

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
end
