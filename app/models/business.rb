# encoding: utf-8
class Business < ActiveRecord::Base
  belongs_to :treasury
  has_many :shares, :dependent => :destroy, :class_name => 'BusinessShare'
  has_many :categories, :dependent => :nullify

  validates :name, :uniqueness => { :scope => :treasury_id }
  validates_with SameTreasuryValidator, :assoc => [:categories, :shares]

  accepts_nested_attributes_for :shares, :allow_destroy => true,
    :reject_if => proc{|attributes| attributes['share'].blank? or attributes['person_id'].blank? }
end
