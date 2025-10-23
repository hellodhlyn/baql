class AddEventStages < ActiveRecord::Migration[8.0]
  def change
    create_table :event_stages do |t|
      t.string :uid, null: false
      t.string :event_uid, null: false
      t.string :name, null: false
      t.integer :difficulty, null: false
      t.string :index, null: false
      t.integer :entry_ap, null: true
      t.timestamps

      t.index [:uid], unique: true
      t.index [:event_uid]
    end

    create_table :event_stage_rewards do |t|
      t.string :stage_uid, null: false
      t.string :reward_type, null: false
      t.string :reward_uid, null: false
      t.string :reward_requirement
      t.integer :amount, null: false
      t.integer :amount_min
      t.integer :amount_max
      t.decimal :chance, precision: 10, scale: 4
      t.jsonb :bonuses, default: {}
      t.timestamps

      t.index [:stage_uid]
    end
  end
end
