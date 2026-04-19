class AddSeasonToMainStoryVolumes < ActiveRecord::Migration[8.0]
  def change
    add_column :main_story_volumes, :season, :integer

    up_only do
      execute <<~SQL
        UPDATE main_story_volumes
        SET season = 1
        WHERE season IS NULL
      SQL
    end

    change_column_null :main_story_volumes, :season, false
  end
end
