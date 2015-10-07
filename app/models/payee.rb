#
# jelenleg nem hasznalt, de meg lehet ra szukseg
#
class Payee < ActiveRecord::Base
  belongs_to :treasury
  has_many :transactions, :dependent => :nullify
  has_one :person, :dependent => :nullify

  serialize :aliases, ::Serializer::List.new(:separator => ';')

  scope :alias, proc{|id|
    where("aliases LIKE '%%-%s-%%'" % ActiveRecord::Base.connection.quote_string(id))
  }

  validates :name, :uniqueness => { :scope => :treasury_id, :case_sensitive => false }
end
