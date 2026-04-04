class AddRawDataToStudents < ActiveRecord::Migration[8.0]
  def change
    add_column :students, :raw_data, :jsonb, null: false, default: {}
  end
end
