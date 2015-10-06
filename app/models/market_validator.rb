# encoding: utf-8
class MarketValidator < ActiveModel::Validator
  def validate(record)
    account_type = options[:account_type]
    unless record.treasury.current_balance(account_type).zero?
      record.errors.add(:base, "Rendszerhiba: a piac egyenlege nem nulla! (%d)" %
        record.treasury.current_balance(account_type))
    end
  end
end
