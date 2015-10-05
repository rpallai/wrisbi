# encoding: utf-8
class Family::Treasury < Treasury
  # :class_name override
  has_many :people, :dependent => :destroy

  has_one :person, -> { where(type_code: Family::Person::Owner) }

  Titles = [
    Family::Title::Deal,
    Title::TransferHead,
  ]

  after_create :create_skeleton

  def people_with_share
    people
  end

  def self.type_name
    "Család"
  end
  def namespace
    :family
  end

  private
  def create_skeleton
    people.create!(:name => name, :type_code => Family::Person::Owner)
  end
end
