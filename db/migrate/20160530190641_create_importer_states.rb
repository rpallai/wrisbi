class CreateImporterStates < ActiveRecord::Migration
  def change
    create_table :importer_states do |t|
      t.string :key, length: 32, null: false
      t.string :value, null: false
    end
  end
end
