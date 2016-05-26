class AddIndexToPartiesTransaction < ActiveRecord::Migration
  def change
    add_index :parties, :transaction_id
  end
end
