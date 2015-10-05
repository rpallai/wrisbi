# encoding: utf-8
#
# Az egy peldanyon belul kezelt kulonbozo kincstarak kozt semmi atjaras nincs, epp olyanok, mintha
# kulonbozo peldanyokban lennenek vezetve.
#
# Minden kincstarhoz tartozik egy vagy tobb fokonyvelo, akik teljes bizalommal vannak egymas irant.
# Tartozhatnak a kincstarhoz konyvelok is, akiknek a muveleteit egy fokonyvelonek jova kell hagynia.
# A konyvelok teljes read joggal rendelkeznek a kincstar folott, kiveve az account#hidden?=>true
# szamlakat. A hidden szamlat erinto manovereket latjak, csak az adott szamlan levo muveletet nem.
# A kulsosok nem rendelkeznek read/write joggal, kiveve sajat szamlajuk muveleteit (account/show/n),
# emiatt nem is kepesek erdemben konyvelest vezetni itt, nem is varhato el toluk; helyette kezi vagy
# automatizalt ertesiteseket kuldhetnek amiket egy leprogramozott importer modul beemel.
#
class Treasury < ActiveRecord::Base
  has_many :supervisings, :dependent => :destroy
  has_many :supervisors, :through => :supervisings, :source => :user

  has_many :payees, :dependent => :destroy
  has_many :categories, :dependent => :destroy
  has_many :businesses, :dependent => :destroy
  has_many :people, :dependent => :destroy

  module AccountsExtension
    def scope_date
      if date_scope = proxy_association.owner.date_scope
        joins(:operations => :transaction).
          where("transactions.date BETWEEN ? AND ?", date_scope.first, date_scope.last)
      else
        self
      end
    end

    def balance(currency)
      joins(:operations).where(currency: currency).scope_date.sum('operations.amount')
    end
  end

  has_many :accounts, -> { extending AccountsExtension }, :through => :people
  has_many :asset_accounts,     -> { where(type_code: Account::T_wallet).extending AccountsExtension }, :through => :people, :source => :accounts
  has_many :liability_accounts, -> { where(type_code: Account::T_cash).extending AccountsExtension }, :through => :people, :source => :accounts

  has_many :operations, :through => :accounts do
    def scope_date
      if date_scope = proxy_association.owner.date_scope
        joins(:transaction).where("transactions.date BETWEEN ? AND ?", date_scope.first, date_scope.last)
      else
        self
      end
    end
  end

	has_many :transactions, :dependent => :destroy
  has_many :titles, :through => :transactions

  has_many :exporters, :dependent => :destroy

  validates_presence_of :name

  def person_of_user(current_user)
		people.find_by_user_id(current_user)
  end

  def equity_balance(currency)
    asset_accounts.balance(currency) + liability_accounts.balance(currency)
  end

  def currencies
    accounts.select(:currency).distinct.map(&:currency)
  end

  # minden balance muvelet csak az adott idointervallumon dolgozik
  def self.set_date_scope(start_date, end_date)
    @@date_scope = [start_date, end_date]
  end
  def self.reset_data_scope
    @@date_scope = nil
  end
  def date_scope
    @@date_scope ||= nil
  end
end
