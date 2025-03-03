class AddRaidIndexToRaids < ActiveRecord::Migration[8.0]
  def change
    add_column :raids, :raid_index_jp, :bigint, null: true
    add_column :raids, :rank_visible, :boolean, null: false, default: false
  end
end
