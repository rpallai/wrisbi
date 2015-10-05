# encoding: utf-8
class BusinessShare < BasicShare
  self.table_name = 'business_shares'

  belongs_to :person
  belongs_to :business

  validates :person_id, :uniqueness => { :scope => :business_id }

  delegate :treasury, :to => :person
end
