class RemoveItemRawDataDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :items, :raw_data, from: {}, to: nil
  end
end
