class AddEventStages < ActiveRecord::Migration[8.0]
  def change
    create_table :event_stages do |t|
      t.string :uid, null: false
      t.string :event_uid, null: false
      t.string :name, null: false
      t.integer :difficulty, null: false
      t.string :index, null: false
      t.integer :entry_ap, null: false
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
      t.timestamps

      t.index [:stage_uid]
    end

    create_table :event_stage_reward_bonuses do |t|
      t.string :reward_resource_type, null: false
      t.string :reward_resource_uid, null: false
      t.string :student_uid, null: false
      t.decimal :ratio, precision: 10, scale: 4
      t.timestamps

      t.index [:reward_resource_type, :reward_resource_uid, :student_uid], unique: true
      t.index [:student_uid]
    end

    create_table :event_shop_resources do |t|
      t.string :event_uid, null: false
      t.string :uid, null: false
      t.string :resource_type, null: false
      t.string :resource_uid, null: false
      t.integer :resource_amount, null: false
      t.string :payment_resource_type, null: false
      t.string :payment_resource_uid, null: false
      t.integer :payment_resource_amount, null: false
      t.integer :shop_amount, null: true
      t.timestamps

      t.index [:event_uid]
    end

    create_table :resources do |t|
      t.string :type, null: false
      t.string :uid, null: false
      t.string :name, null: false
      t.string :category, null: false
      t.string :sub_category
      t.integer :rarity, null: false
      t.timestamps

      t.index [:type, :uid], unique: true
    end
  end
end
