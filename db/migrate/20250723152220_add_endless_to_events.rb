class AddEndlessToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :endless, :boolean, default: false, null: false
    change_column_null :pickups, :until, true
  end
end
