class CreateStagesAndGachaGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :gacha_groups do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.jsonb :raw_data, null: false
      t.timestamps

      t.index :uid, unique: true
    end

    create_table :stages do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :category, null: false
      t.string :stage_type
      t.integer :difficulty
      t.integer :area
      t.string :stage_number
      t.string :terrain
      t.integer :level
      t.jsonb :raw_data, null: false
      t.timestamps

      t.index :uid, unique: true
      t.index :category
    end
  end
end
