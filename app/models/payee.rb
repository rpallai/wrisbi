class Payee < ActiveRecord::Base
  belongs_to :treasury
  has_many :transactions, :dependent => :nullify
  has_one :person, :dependent => :nullify

  serialize :aliases, ::Serializer::List.new(:separator => ';')

  scope :alias, proc{|id|
    where("aliases LIKE '%%-%s-%%'" % ActiveRecord::Base.connection.quote_string(id))
  }

  validates :name, :uniqueness => { :scope => :treasury_id, :case_sensitive => false }

  #  def destroy
  #    raise ActiveRecord::ActiveRecordError, "assert operations.empty? failed" unless operations.empty?
  #    raise ActiveRecord::ActiveRecordError, "assert avatar.nil? failed" unless avatar.nil?
  #    super
  #  end
end
