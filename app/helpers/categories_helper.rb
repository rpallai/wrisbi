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

#  def rearrange_list(node, stack = "", depth = 0, &block)
#    depth += 1
#    node.each {|k, v|
#      stack << capture do
#        yield(k, depth) || ''
#      end
#      unless v.empty?
#        rearrange_list(v, stack, depth, &block)
#      end
#    }
#    stack
#  end

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
