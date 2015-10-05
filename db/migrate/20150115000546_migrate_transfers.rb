class MigrateTransfers < ActiveRecord::Migration
  def up
    Maneuver.where('type IN (?)', %w(Household::Maneuver::Transfer Limited::Maneuver::MoneyTransfer Household::Maneuver::CurrencyExchange)).each do |maneuver|
      # megsemmisitjuk a regit, johetnek az ujak
      transaction = maneuver.transaction
      transaction.ratio = maneuver.transfer_ratio
      new_maneuver_left = Maneuver::TransferHead.new(
        party: transaction.parties.left,
        amount: transaction.parties.left.amount,
        comment: '',
      )
      new_maneuver_right = Maneuver::TransferHead.new(
        party: transaction.parties.right,
        amount: transaction.parties.right.amount,
        comment: '',
      )

      puts maneuver.inspect, "-->"
      puts transaction.inspect, new_maneuver_left.inspect, new_maneuver_right.inspect
      puts

      Transaction.transaction do
        maneuver.destroy
        new_maneuver_left.save!
        new_maneuver_right.save!
        transaction.save!
      end
    end
  end
end
