# encoding: utf-8
class Family::Person < Person
  General = 0
  Owner = 1

  # :class_name override
  has_many :accounts, :dependent => :destroy

  after_create :create_liability_account

  def self.possible_type_codes
    { 'Általános' => General }
  end

  def koltopenz_accounts
    asset_accounts.find_all{|a| a.subtype_code == Family::Account::St_koltopenz }
  end
  def koltopenz_account_in(currency)
    koltopenz_accounts.find{|a| a.currency == currency }
  end

  # folosleges, konnyen attekintheto
  def equity
    0
  end

  def member?
    asset_accounts.account > 0
  end

  private
  def create_liability_account
    unless type_code == Owner
      accounts.create!(:name => "Készpénz (HUF)", :currency => "HUF", :type_code => Account::T_cash)
    end
  end
end
