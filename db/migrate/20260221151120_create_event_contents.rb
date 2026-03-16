class CreateEventContents < ActiveRecord::Migration[8.0]
  def change
    ### Translation
    create_table :translations do |t|
      t.string :language, null: false
      t.string :key, null: false
      t.text :value, null: false
      t.timestamps

      t.index [:key, :language], unique: true
    end

    ### Event contents
    create_table :event_contents do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.jsonb :raw_data_first
      t.jsonb :raw_data_rerun
      t.timestamps

      t.index :uid, unique: true
    end

    create_table :event_content_schedules do |t|
      t.string :event_content_uid, null: false
      t.string :region, null: false
      t.string :run_type, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: true

      t.timestamps

      t.index [:event_content_uid, :region, :run_type], unique: true
      t.index [:region, :start_at, :end_at]
    end

    ### Resources
    remove_column :items, :name, :string
    add_column :items, :baql_id, :string, null: false, default: ""
    add_column :items, :raw_data, :jsonb, null: false, default: {}

    Item.all.each do |item|
      item.update!(baql_id: "baql::items::#{item.uid}")
    end

    create_table :furnitures do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :category, null: false
      t.string :sub_category
      t.integer :rarity, null: false
      t.string :tags, array: true, default: [], null: false
      t.jsonb :raw_data, null: false
      t.timestamps

      t.index :uid, unique: true
    end

    create_table :equipments do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :category, null: false
      t.string :sub_category
      t.integer :rarity, null: false
      t.jsonb :raw_data, null: false
      t.timestamps

      t.index :uid, unique: true
    end

    create_table :currencies do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.integer :rarity, null: false
      t.jsonb :raw_data, null: false
      t.timestamps

      t.index :uid, unique: true
    end
  end
end
