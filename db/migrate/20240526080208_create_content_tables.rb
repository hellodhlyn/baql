class CreateContentTables < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :event_id, null: false
      t.string :name, null: false
      t.string :type, null: false
      t.boolean :rerun, null: false
      t.datetime :since, null: false
      t.datetime :until, null: false
      t.string :image_url
      t.jsonb :videos
      t.jsonb :pickups
      t.jsonb :tips
      t.boolean :visible, null: false, default: false
      t.timestamps

      t.index :event_id, unique: true
      t.index :since
    end

    create_table :raids do |t|
      t.string :raid_id, null: false
      t.string :name, null: false
      t.string :boss, null: false
      t.string :type, null: false
      t.string :terrain
      t.string :attack_type
      t.string :defense_type
      t.datetime :since, null: false
      t.datetime :until, null: false
      t.boolean :visible, null: false, default: false
      t.timestamps

      t.index :raid_id, unique: true
      t.index :since
    end
  end
end
