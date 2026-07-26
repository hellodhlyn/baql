class AllowNullResourceRawData < ActiveRecord::Migration[8.1]
  def change
    change_column_null :currencies, :raw_data, true
    change_column_null :equipments, :raw_data, true
    change_column_null :furnitures, :raw_data, true
  end
end
