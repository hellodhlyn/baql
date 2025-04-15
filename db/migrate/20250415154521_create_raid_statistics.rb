class CreateRaidStatistics < ActiveRecord::Migration[8.0]
  def change
    create_table :raid_statistics do |t|
      t.string :student_id, null: false
      t.bigint :raid_id, null: false
      t.string :defense_type, null: false
      t.string :difficulty, null: false
      t.jsonb :counts_by_tier, null: false
      t.timestamps
    end

    add_index :raid_statistics, [:student_id, :raid_id, :defense_type], unique: true
    add_index :raid_statistics, [:raid_id]
  end
end
