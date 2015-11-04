module CategoriesHelper
  # returns level 1 nested array
  def rearrange(tree, prefix = nil)
    prefix = prefix ? prefix+"/" : ""
    ret = []
    tree.each do |p,c|
      name = p.name
      # Cseri kérése, hogy legyen mellette az egyezség is
      name += " [#{p.applied_business.name}]" if p.applied_business
      ret << [prefix+name, p.id]
      ret += rearrange(c, prefix+p.name)
    end
    ret
  end

  def treasury_categories(treasury)
    rearrange(
      Category.where(treasury: treasury).includes(:applied_business).arrange
    ).sort
  end

  def each_treasury_categories_list2(parent, children, stack, depth, subtotal, row_printer, subtotals_printer)
    depth += 1
    my_subtotal = {
      subtree_elements: 0,
      titles_count: parent ? parent.titles_count : 0,
      kiadas: parent ? parent.kiadas : 0,
      bevetel: parent ? parent.bevetel : 0,
    }
    children.each {|k,v|
      my_subtotal[:subtree_elements] += 1
      stack << capture{ row_printer.call(k, depth) }
      each_treasury_categories_list2(k, v, stack, depth, my_subtotal, row_printer, subtotals_printer)
    }
    unless my_subtotal[:subtree_elements].zero?
      stack << capture{ subtotals_printer.call(children, depth, my_subtotal) }
    end
    my_subtotal.each{|k,v| subtotal[k] += v }
    stack
  end

  def each_treasury_categories_list(treasury, row_printer, subtotals_printer)
    subtotal = {
      subtree_elements: 0,
      titles_count: 0,
      kiadas: 0,
      bevetel: 0,
    }
    each_treasury_categories_list2(
      nil,
      Category.where(treasury: treasury).
        joins("LEFT JOIN `categories_titles` ON `categories_titles`.`category_id` = `categories`.`id` "<<
          "LEFT JOIN `titles` ON `titles`.`id` = `categories_titles`.`title_id`").
        group('categories.id').
        select("`categories`.*, COUNT(`titles`.`id`) AS titles_count, "<<
          "SUM(CASE WHEN amount<0 THEN amount ELSE 0 END) AS kiadas, "<<
          "SUM(CASE WHEN amount>0 THEN amount ELSE 0 END) AS bevetel").
        includes(:business, :applied_business).
        arrange(:order => :name),
      "", 0, subtotal, row_printer, subtotals_printer
    )
  end

  def each_treasury_categories_tree2(node, stack = "", &block)
    node.each {|k, v|
      stack << "<li>"
      stack << capture do
        yield(k)
      end
      unless v.empty?
        stack << "<ol>"
        each_treasury_categories_tree2(v, stack, &block)
        stack << "</ol>"
      end
      stack << "</li>"
    }
    stack
  end

  # fa-strukturaba (ol element) rendezi a kimenetet, az egyes sorok tartalmat a &block szolgaltatja
  def each_treasury_categories_tree(treasury, &block)
    each_treasury_categories_tree2(
      Category.where(treasury: treasury).includes(:business, :applied_business).arrange, "", &block
    )
  end

  def treasury_categories_with_title(treasury)
    Category.where(treasury: treasury).joins(:titles).group(:id).
      map{|p| [ p.ancestors.push(p).map(&:name)*'/', p.id ]}.sort
  end

  def find_category(treasury, path)
    category = nil
    categories = treasury.categories.roots
    path.split('/').each do |name|
      unless name.blank?
        category = categories.find_by_name(name)
        categories = category.children
      end
    end
    return category
  end
end
