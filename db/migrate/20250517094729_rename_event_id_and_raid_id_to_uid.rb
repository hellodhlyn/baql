class RenameEventIdAndRaidIdToUid < ActiveRecord::Migration[8.0]
  def change
    rename_column :events, :event_id, :uid
    rename_column :raids, :raid_id, :uid
  end
end
