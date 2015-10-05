class BindManeuversToParty < ActiveRecord::Migration
  def up
    # beallitjuk a party-t
    Maneuver.where(:party_id => 0).each do |maneuver|
      transaction = maneuver.transaction
      raise "transaction.parties.count > 1" if transaction.parties.count > 1
      maneuver.update_columns(party_id: transaction.parties.first)
    end
  end
end
