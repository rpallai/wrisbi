class AddExpiresAtToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :expires_at, :date
  end
end
