# encoding: utf-8
class Category < ActiveRecord::Base
  has_ancestry

  belongs_to :treasury
  belongs_to :business
  belongs_to :applied_business, class_name: 'Business'
  belongs_to :exporter
  has_many :category_links
  has_many :titles, :through => :category_links, :dependent => :destroy

  validates :name, :uniqueness => { :scope => [:treasury_id, :ancestry] }
  validates_with SameTreasuryValidator, :assoc => [:business, :parent]

  before_save :set_applied_business
  after_update :set_applied_business_r

  def titles_r
    ids = Title.joins(:categories).where("categories.id IN (?)", subtree.ids).pluck('titles.id')
    Title.where(id: ids)
  end

  def find_business
    ([self] + ancestors.reverse).each do |walker|
      #logger.debug "<category>.shares: finding on %s" % [walker.name]
      if walker.business
        #logger.debug "found share(s) %s for category %s" % [walker.business.shares.map(&:to_s), walker.name]
        return walker.business
      end
    end
    nil
  end

  private
  def set_applied_business
    if ancestry_changed? or new_record?
      self.applied_business = find_business
    end
  end
  def set_applied_business_r
    if business_id_changed?
      #logger.debug "subtree1: #{subtree.map(&:id).inspect}"
      # a subtree valamiert a regi ancestry-t hasznalja, hiaba valtozott meg - ez a workaround
      reload
      #logger.debug "subtree2: #{subtree.map(&:id).inspect}"
      subtree.each do |category|
        category.update!(applied_business: category.find_business)
      end
    end
  end
end
