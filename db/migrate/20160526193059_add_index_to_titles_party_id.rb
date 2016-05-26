class AddIndexToTitlesPartyId < ActiveRecord::Migration
  def change
    add_index :titles, :party_id
  end
end
