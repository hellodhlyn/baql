class CreateEventContentRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :event_content_runs do |t|
      t.string :event_content_uid, null: false
      t.string :run_type, null: false
      t.bigint :source_event_content_uid, null: false
      t.integer :position, null: false
      t.timestamps

      t.index [:event_content_uid, :run_type], unique: true
    end

    create_table :event_content_run_stages do |t|
      t.bigint :event_content_run_id, null: false
      t.string :uid, null: false
      t.string :stage_type, null: false
      t.integer :stage_index, null: false
      t.string :stage_number, null: false
      t.string :enter_cost_type, null: false
      t.string :enter_cost_uid, null: false
      t.integer :enter_cost_amount, null: false
      t.integer :position, null: false
      t.timestamps

      t.index [:event_content_run_id, :uid], unique: true
      t.index [:enter_cost_type, :enter_cost_uid]
    end

    create_table :event_content_run_stage_rewards do |t|
      t.bigint :event_content_run_stage_id, null: false
      t.string :reward_type, null: false
      t.string :reward_uid, null: false
      t.integer :amount, null: false
      t.decimal :probability, precision: 10, scale: 4, null: false
      t.string :tag, null: false
      t.integer :position, null: false
      t.timestamps

      t.index [:event_content_run_stage_id, :position], unique: true
      t.index [:reward_type, :reward_uid]
    end

    create_table :event_content_run_bonuses do |t|
      t.bigint :event_content_run_id, null: false
      t.string :student_uid, null: false
      t.string :reward_type, null: false
      t.string :reward_uid, null: false
      t.decimal :percentage, precision: 10, scale: 4, null: false
      t.integer :position, null: false
      t.timestamps

      t.index [:event_content_run_id, :student_uid, :reward_type, :reward_uid], unique: true, name: "idx_event_run_bonuses_unique"
      t.index :student_uid
      t.index [:reward_type, :reward_uid]
    end

    create_table :event_content_run_shop_resources do |t|
      t.bigint :event_content_run_id, null: false
      t.string :uid, null: false
      t.string :resource_type, null: false
      t.string :resource_uid, null: false
      t.integer :resource_amount, null: false
      t.string :payment_resource_type, null: false
      t.string :payment_resource_uid, null: false
      t.integer :payment_resource_amount, null: false
      t.integer :shop_amount
      t.integer :position, null: false
      t.timestamps

      t.index [:event_content_run_id, :uid], unique: true, name: "idx_event_run_shop_resources_unique"
      t.index [:resource_type, :resource_uid]
      t.index [:payment_resource_type, :payment_resource_uid], name: "idx_event_run_shop_payment_resource"
    end

    create_table :event_content_run_shop_purchase_tiers do |t|
      t.bigint :event_content_run_shop_resource_id, null: false
      t.integer :tier_index, null: false
      t.integer :start_quantity, null: false
      t.integer :quantity
      t.integer :unit_price, null: false
      t.string :payment_resource_type, null: false
      t.string :payment_resource_uid, null: false
      t.timestamps

      t.index [:event_content_run_shop_resource_id, :tier_index], unique: true, name: "idx_event_run_shop_tiers_unique"
    end

    create_table :event_content_run_minigames do |t|
      t.bigint :event_content_run_id, null: false
      t.string :minigame_type, null: false
      t.integer :position, null: false
      t.jsonb :config, null: false
      t.timestamps

      t.index [:event_content_run_id, :minigame_type], unique: true, name: "idx_event_run_minigames_unique"
    end
  end
end
