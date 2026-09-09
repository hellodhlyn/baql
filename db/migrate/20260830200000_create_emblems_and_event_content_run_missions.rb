class CreateEmblemsAndEventContentRunMissions < ActiveRecord::Migration[8.0]
  def change
    create_table :emblems do |t|
      t.string :baql_id, null: false
      t.string :category, null: false
      t.integer :rarity, null: false
      t.jsonb :raw_data, null: false
      t.jsonb :image_asset_keys, null: false, default: {}
      t.string :uid, null: false
      t.timestamps

      t.index :uid, unique: true
    end

    create_table :event_content_run_missions do |t|
      t.bigint :event_content_run_id, null: false
      t.string :uid, null: false
      t.string :category, null: false
      t.string :reset_type, null: false
      t.integer :display_order, null: false
      t.integer :position, null: false
      t.jsonb :localizations, null: false
      t.string :condition_type, null: false
      t.integer :condition_count, null: false
      t.jsonb :condition_parameters, null: false
      t.jsonb :condition_parameter_tags, null: false
      t.string :reward_type, null: false
      t.string :reward_uid, null: false
      t.integer :reward_amount, null: false
      t.string :condition_reward_type
      t.string :condition_reward_uid
      t.integer :condition_reward_amount
      t.string :pre_mission_uid
      t.string :completion_reference_mission_uid
      t.integer :completion_reference_required_count, null: false, default: 0
      t.boolean :completion_extension, null: false
      t.timestamps

      t.index [:event_content_run_id, :uid], unique: true, name: "idx_event_run_missions_unique"
      t.index [:event_content_run_id, :position], name: "idx_event_run_missions_position"
      t.index [:reward_type, :reward_uid], name: "idx_event_run_missions_reward"
      t.index [:condition_reward_type, :condition_reward_uid], name: "idx_event_run_missions_condition_reward"
    end
  end
end
