# encoding: utf-8
class Account < ActiveRecord::Base
  # Valós pénz. Pl bankszámla, hitelkártya, készpénztartalék. Megszámolható.
  T_wallet = 0
  # Elszámolási számla, készpénzben. Átruházható, likvid.
  T_cash = 1
  # Kincstáron kívül keletkezett követelések nyilvántartása, pl leosztas vegett.
  T_auxiliary = 2

  belongs_to :person
  belongs_to :exporter
  has_many :parties, :dependent => :destroy
  has_many :operations, :dependent => :destroy do
    def scope_date
      if date_scope = proxy_association.owner.treasury.date_scope
        joins(:transaction).where("transactions.date BETWEEN ? AND ?", date_scope.first, date_scope.last)
      else
        self
      end
    end
  end
  has_many :titles, :through => :operations

  attr_writer :type_user

  serialize :foreign_ids, ::Serializer::List.new

  validates :name, :presence => true, :uniqueness => { :scope => [:person_id] }
  validates :currency, presence: true, :length => { :is => 3 }
  validates_presence_of :closed, :type_code

  scope :opened, where(:closed => false)
  scope :none, where('0 = 1')
  scope :foreign_id, proc{|id|
    where("accounts.foreign_ids LIKE '%%-%s-%%'" % ActiveRecord::Base.connection.quote_string(id))
  }

  delegate :treasury, :to => :person

  def balance
    operations.scope_date.sum(:amount)
  end
  def volume
    operations.scope_date.sum("ABS(amount)")
  end

  def full_name
    person.name + '-' + name
  end

  def asset?
    type_code == T_wallet
  end
  def liability?
    type_code == T_cash
  end
  def auxiliary?
    type_code == T_auxiliary
  end

  def type_name
    case type_code
    when T_wallet then :wallet
    when T_cash then :cash
    when T_auxiliary then :auxiliary
    end
  end
end
