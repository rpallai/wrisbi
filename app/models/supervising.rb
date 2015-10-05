# encoding: utf-8
class Supervising < ActiveRecord::Base
  belongs_to :user
  belongs_to :treasury
end
