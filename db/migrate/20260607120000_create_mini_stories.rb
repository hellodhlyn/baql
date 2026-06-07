# frozen_string_literal: true

class CreateMiniStories < ActiveRecord::Migration[8.0]
  def change
    create_table :mini_stories do |t|
      t.string  :uid,           null: false
      t.string  :baql_id,       null: false
      t.integer :episode_count, null: false

      t.timestamps

      t.index :uid, unique: true
    end

    create_table :mini_story_schedules do |t|
      t.string   :mini_story_uid, null: false
      t.string   :region,         null: false
      t.datetime :released_at,    null: false

      t.timestamps

      t.index [:mini_story_uid, :region], unique: true
      t.index [:region, :released_at]
    end
  end
end
