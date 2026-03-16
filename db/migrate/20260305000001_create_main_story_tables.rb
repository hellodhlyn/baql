class CreateMainStoryTables < ActiveRecord::Migration[8.0]
  def change
    create_table :main_story_volumes do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :label, null: false
      t.integer :sort_order, null: false
      t.timestamps

      t.index :uid, unique: true
      t.index :sort_order
    end

    create_table :main_story_chapters do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :volume_uid, null: false
      t.integer :chapter_number, null: false
      t.timestamps

      t.index :uid, unique: true
      t.index :volume_uid
    end

    create_table :main_story_parts do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :chapter_uid, null: false
      t.integer :sort_order, null: false
      t.integer :episode_start
      t.integer :episode_end
      t.timestamps

      t.index :uid, unique: true
      t.index :chapter_uid
    end

    create_table :main_story_part_schedules do |t|
      t.string :part_uid, null: false
      t.string :region, null: false
      t.datetime :released_at, null: false
      t.boolean :confirmed, null: false, default: false
      t.timestamps

      t.index [:part_uid, :region], unique: true
    end
  end
end
