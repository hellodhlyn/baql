class EnsureStudentRawData < ActiveRecord::Migration[8.0]
  def up
    return if column_exists?(:students, :raw_data)

    add_column :students, :raw_data, :jsonb, null: false, default: {}
  end

  def down
    # Keep source payload columns even when rolling this compatibility migration back.
  end
end
