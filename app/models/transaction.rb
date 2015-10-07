# encoding: utf-8
class Transaction < ActiveRecord::Base
  belongs_to :treasury
  belongs_to :user
  has_many :parties, :dependent => :destroy, :autosave => true, :inverse_of => :transaction do
    def left
      order(:amount).first
    end
    def right
      order(:amount).last
    end
  end
  has_many :accounts, :through => :parties
  has_many :titles, :through => :parties
  has_many :operations, :through => :titles

  attr_accessor :invert

  before_validation :do_invert, :if => :invert?
  before_validation :fill_missing_party_amount

  validates :treasury, :presence => true
  validates :date, :presence => true
  validate :validate_accounts_uniqueness
  validate :validate_transfers

  accepts_nested_attributes_for :parties, :allow_destroy => true

  before_update {|t|
    # ez nem azt jelenti hogy modositva is lett, csak azt, hogy valaki submit-olt egy edit formot
    t.updated_at = Time.now
  }
  after_update {|t|
    if t.comment_changed? or t.date_changed?
      titles.each do |m|
        m.categories.each{|category| category.exporter.after_transaction_update(t) if category.exporter }
      end
    end
  }

  def initialize(opts = {})
    # ehh, a true -t a formbuilder nem checked-nek erzekeli
    @invert = 0 unless opts['invert']
    super
  end

  private
  def invert?
    @invert.to_i == 1
  end

  def do_invert
    # tipikusan csak az elsonel van szukseg erre
    parties.each do |party|
      if party.amount
        party.amount = -party.amount
        party.titles.each do |title|
          title.amount = -title.amount if title.amount
        end
        # ha az elso create nem sikerult es ujra kidobjuk a form-ot a juzernek;
        # nem szabad, hogy a pipa bennmaradjon ha mar megforditottuk az elojelet
        @invert = 0
      end
    end
    return true
  end

  private
  def fill_missing_party_amount
    logger.debug "fill_missing_party_amount; parties.length: #{parties.length}"
    if parties.length == 2 and not parties.all?(&:amount) and parties.any?(&:amount)
      party = parties.find{|p| ! p.amount }
      other_party = parties.find{|p| p != party  }
      party.amount = -other_party.amount
    end
  end

  def validate_accounts_uniqueness
    accounts = parties.map(&:account)
    if accounts.length > accounts.uniq.length
      errors.add(:parties, "nem lehet ugyanaz a számla")
    end
  end

  def validate_transfers
    if parties.length > 1
      transfers = []
      parties.each do |p|
        transfers += p.titles.find_all{|m| m.kind_of? Title::TransferHead }
      end
      transfers_by_currency = transfers.group_by{|m| m.party.account.currency }
      transfers_by_currency.each do |currency,transfers|
        amount_sum = transfers.sum(&:amount)
        unless amount_sum.zero?
          errors.add(:parties, "az összeg nem nulla (#{amount_sum} #{currency})")
        end
      end
      #XXXerrors.add(:parties, "egyező összeg különböző pénznemű számák között")
    end
  end

  #  def right_amount
  #    logger.debug ">>> Zedding: calculating right_amount, transfer_ratio: '#{transfer_ratio}'"
  #    base = amount_netto
  #    if not transfer_ratio or transfer_ratio.blank?
  #      -base
  #    else
  #      if transfer_ratio.is_a? Numeric
  #        transfer_ratio
  #      elsif transfer_ratio.ends_with? '%'
  #        return if base.nil?
  #        Rails.logger.debug(">>> Zedding: turning percentage (#{transfer_ratio}) based on #{base}")
  #        -(base * transfer_ratio.to_i / 100)
  #      end
  #    end
  #  end
end
