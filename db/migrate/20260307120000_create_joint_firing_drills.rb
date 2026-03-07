class CreateJointFiringDrills < ActiveRecord::Migration[8.0]
  def change
    create_table :joint_firing_drills do |t|
      t.string  :uid,         null: false
      t.integer :season,      null: false
      t.string  :drill_type,   null: false
      t.string  :terrain,      null: false
      t.string  :defense_type, null: false
      t.boolean :confirmed,   null: false, default: true
      t.timestamps

      t.index :uid,    unique: true
      t.index :season, unique: true
    end

    create_table :joint_firing_drill_schedules do |t|
      t.string   :drill_uid, null: false
      t.string   :region,    null: false
      t.datetime :start_at,  null: false
      t.datetime :end_at
      t.timestamps

      t.index [:drill_uid, :region], unique: true
      t.index :drill_uid
    end

    add_foreign_key :joint_firing_drill_schedules, :joint_firing_drills,
                    column: :drill_uid, primary_key: :uid
  end
end
