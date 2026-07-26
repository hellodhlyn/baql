class AllowNullItemRawData < ActiveRecord::Migration[8.1]
  def change
    change_column_null :items, :raw_data, true
  end
end
