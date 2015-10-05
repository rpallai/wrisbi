# encoding: utf-8
class Operation < ActiveRecord::Base
  belongs_to :title
  has_one :transaction, :through => :title
  has_one :person, :through => :account
  belongs_to :account

  validates_presence_of :title, :account
  validate do
    errors.add(:account, 'lezárt számla') if account and account.closed?
  end
  validates :amount, :numericality => true
  validate :validate_amount_is_not_zero, :if => :amount

  def type_code_name
    title.class.const_get(:Op).each{|key, value| return key if value == type_code }
    # ha ismeretlen..
    ''
  end

  private
  def validate_amount_is_not_zero
    errors.add(:amount, "nem lehet nulla") if amount.zero?
  end
end
