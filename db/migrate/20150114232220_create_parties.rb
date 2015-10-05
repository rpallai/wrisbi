class CreateParties < ActiveRecord::Migration
  def up
    Party.delete_all

    Transaction.all.each do |t|
      party = t.parties.build(
        account: t.account,
        amount: t.amount,
        payee: t.payee,
      )
      #puts party.inspect
      #break
      party.save!
    end

    Transaction.joins(:maneuvers).where('maneuvers.type IN (?)',
      %w(Household::Maneuver::Transfer Household::Maneuver::CurrencyExchange Limited::Maneuver::MoneyTransfer)
    ).each do |t|
      transfer = t.maneuvers.first
      party = t.parties.build(
        account: transfer.right.account,
        amount: transfer.right.amount,
      )
      #puts party.inspect
      #break
      party.save!
    end
  end
end
