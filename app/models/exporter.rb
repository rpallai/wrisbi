# encoding: utf-8
class Exporter < ActiveRecord::Base
  belongs_to :treasury
  has_many :accounts, :dependent => :nullify
  has_many :categories, :dependent => :nullify

  validates_presence_of :treasury

  serialize :cfg
end
