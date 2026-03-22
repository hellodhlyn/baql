class CreateRaidBossesAndRaidSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :raid_bosses do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :raid_type, null: false
      t.string :event_content_uid
      t.timestamps

      t.index :uid, unique: true
      t.index :event_content_uid
    end

    create_table :raid_schedules do |t|
      t.string  :uid,           null: false
      t.string  :baql_id,       null: false
      t.string  :raid_boss_uid, null: false
      t.string  :region,        null: false
      t.string  :raid_type,     null: false
      t.integer :season_index,  null: false
      t.string  :terrain,       null: false
      t.datetime :start_at
      t.datetime :end_at
      t.jsonb   :defense_types,             default: []
      t.string  :attack_type
      t.integer :jp_season_index
      t.string  :event_content_run_type
      t.timestamps

      t.index :uid, unique: true
      t.index [:region, :raid_type, :season_index], unique: true
      t.index [:region, :start_at, :end_at]
      t.index :raid_boss_uid
      t.index [:raid_type, :jp_season_index]
    end
  end
end
