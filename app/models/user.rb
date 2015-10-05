class User < ActiveRecord::Base
  has_many :people, :dependent => :nullify

  has_many :supervisings, :dependent => :destroy
  #XXX nem eleg kifejezo elnevezes
  has_many :treasuries, :through => :supervisings
  has_many :concerned_treasuries, :through => :people, :source => :treasury

  has_secure_password

  validates :email, :uniqueness => true,
    :format => { :with => %r/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/ }
end
