class RenameVisibleToConfirmedOnContentTables < ActiveRecord::Migration[8.0]
  def change
    rename_column :events, :visible, :confirmed
    rename_column :raids, :visible, :confirmed

    change_column :events, :confirmed, :boolean, default: false, null: false
    change_column :raids, :confirmed, :boolean, default: false, null: false
  end
end
