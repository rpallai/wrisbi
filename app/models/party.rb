# encoding: utf-8
class Party < ActiveRecord::Base
  belongs_to :transaction
  #has_one :treasury, :through => :transaction
  belongs_to :account
  belongs_to :payee
  has_many :titles, :dependent => :destroy, :autosave => true, :inverse_of => :party
  has_many :operations, :through => :titles

  attr_accessor :payee_name

  delegate :treasury, :to => :transaction

  before_validation :fill_missing_title_amount, :if => :amount
  #after_validation :create_payee, :if => 'not payee and not payee_name.blank?'

  validates :amount, :numericality => { other_than: 0 }
  validates :account_id, :presence => true
  validates_with SameTreasuryValidator, :assoc => [:account]
  validate :validate_total_amount_of_titles_equal_to_amount, :if => :amount

  accepts_nested_attributes_for :titles, :allow_destroy => true

  def other_party
    transaction.parties.find{|p| p != self }
  end

  def find_compatible_title_klasses
    if account
      titles = treasury.class.const_get :Titles
      titles.find_all{|m_klass| m_klass.compatible?(self) }
    else
      # ures a szamla: barmi lehet
      # nehany template igy mukodik, csak tetelt valaszt, szamlat nem
      titles = treasury.class.const_get(:Titles)
    end
  end

  private
  def titles_amount_sum
    total_sum = 0
    titles.each{|m| total_sum += m.amount if m.amount and not m.marked_for_destruction? }
    total_sum
  end

  def validate_total_amount_of_titles_equal_to_amount
    titles_without_amount = titles.find_all{|m| not m.amount }
    if titles_without_amount.length > 1
      titles_without_amount.each{|m|
        m.errors.add(:amount, "Maximum 1-nél hagyhatod üresen")
      }
    end
    if titles.length.zero?
      errors.add(:base, "Nincs megadva tétel")
    else
      unless titles_amount_sum == amount
        errors.add(:amount, "A tételek nem fedik le az összeget (%d vs %d)" % [titles_amount_sum, amount])
      end
    end
  end

  def fill_missing_title_amount
    logger.debug "fill_missing_title_amount; titles.length: #{titles.length}"
    living_titles = titles.to_a.find_all{|m| not m.marked_for_destruction? }
    titles_without_amount = living_titles.find_all{|m| ! m.amount }
    if living_titles.length == 1
      living_titles.first.amount = amount
    elsif titles_without_amount.length == 1
      m = titles_without_amount.first
      m.amount = amount - titles_amount_sum
    end
  end

  def create_payee
    self.payee = Payee.find_by_name(payee_name) or
      create_payee!(:name => payee_name, :treasury => treasury)
  end
end
