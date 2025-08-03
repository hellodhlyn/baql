class AddRaidVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :raid_videos do |t|
      t.string :title, null: false
      t.bigint :score, null: false
      t.string :youtube_id, null: false
      t.string :thumbnail_url, null: false
      t.datetime :published_at, null: false

      t.string :raid_type, null: false
      t.string :raid_boss, null: false
      t.string :raid_terrain, null: false
      t.string :raid_defense_type, null: false

      t.timestamps

      t.index [:raid_type, :raid_boss, :raid_terrain, :raid_defense_type]
    end
  end
end
