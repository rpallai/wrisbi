# encoding: utf-8
class SameTreasuryValidator < ActiveModel::Validator
  def validate(record)
    options[:assoc].each {|association_name|
      relation = record.send(association_name)

      valid = true
      if relation.nil?
      elsif relation.is_a? Enumerable or relation.is_a? ActiveRecord::Associations::CollectionProxy
        valid = false if relation.any?{|a| a.treasury != record.treasury }
      else
        valid = false if record.treasury != relation.treasury
      end

      record.errors.add(:base, "Foreign treasury in association: %s" % [association_name]) unless valid
    }
  end
end
