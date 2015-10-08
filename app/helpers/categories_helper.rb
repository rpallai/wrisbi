module CategoriesHelper
  def treasury_categories(treasury, klass)
    Rails.logger.silence do
      # Cseri kerese, hogy legyen mellette az egyezseg is
      klass.where(treasury: treasury).map{|p|
        name = p.ancestors.push(p).map(&:name)*'/'
        name += " [#{p.applied_business.name}]" if p.applied_business
        [ name, p.id ]
      }.sort
    end
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
