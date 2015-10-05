class Person < ActiveRecord::Base
  belongs_to :treasury

  has_many :accounts, :dependent => :destroy
  # ezeknek a szamlaknak az osszege mutatja tisztan a reszesedest
  has_many :accounts_for_equity, -> { where(type_code: [Account::T_wallet, Account::T_cash]) }, :class_name => "Account"

  has_many :business_shares, :dependent => :destroy
  has_many :shares, :dependent => :destroy
  belongs_to :user

  serialize :foreign_ids, ::Serializer::List.new

  validates_presence_of :name, :type_code

  scope :foreign_id, proc{|id|
		where("people.foreign_ids LIKE '%%-%s-%%'" % ActiveRecord::Base.connection.quote_string(id))
  }

  def account_of(type_code)
    accounts.to_a.find{|a| a.type_code == type_code }
  end
  alias_method :account, :account_of
  def accounts_of(type_code)
    accounts.to_a.find_all{|a| a.type_code == type_code }
  end

  def asset_accounts
    accounts_of(Account::T_wallet)
  end
  def liability_accounts
    accounts_of(Account::T_cash)
  end
  def first_cash_account_in(currency)
		liability_accounts.find{|a| a.currency == currency }
  end

  def bookkeeper?
		! restricted?
  end
end
