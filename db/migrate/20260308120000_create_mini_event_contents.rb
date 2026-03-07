class CreateMiniEventContents < ActiveRecord::Migration[8.0]
  def change
    create_table :mini_event_contents do |t|
      t.string :uid,     null: false
      t.string :baql_id, null: false
      t.timestamps

      t.index :uid, unique: true
    end

    create_table :mini_event_content_schedules do |t|
      t.string   :mini_event_content_uid, null: false
      t.string   :region,                 null: false
      t.integer  :occurrence,             null: false
      t.datetime :start_at,               null: false
      t.datetime :end_at,                 null: false
      t.timestamps

      t.index [:mini_event_content_uid, :region, :occurrence], unique: true, name: "index_mini_event_content_schedules_unique"
      t.index [:region, :start_at, :end_at]
    end
  end
end
