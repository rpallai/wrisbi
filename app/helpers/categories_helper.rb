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
