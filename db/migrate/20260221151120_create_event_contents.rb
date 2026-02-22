class CreateEventContents < ActiveRecord::Migration[8.0]
  def change
    create_table :translations do |t|
      t.string :language, null: false
      t.string :key, null: false
      t.text :value, null: false
      t.timestamps

      t.index [:key, :language], unique: true
    end

    create_table :event_contents do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false

      t.timestamps

      t.index :uid, unique: true
    end

    create_table :event_content_schedules do |t|
      t.references :event_content, null: false, foreign_key: true
      t.string :region, null: false
      t.string :run_type, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: true

      t.timestamps

      t.index [:event_content_id, :region, :run_type], unique: true
      t.index [:region, :start_at, :end_at]
    end
  end
end
