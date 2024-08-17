class AddEventIndexToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :event_index, :bigint, null: true
  end
end
