class AddArchiveAtToStudents < ActiveRecord::Migration[8.0]
  def change
    add_column :students, :archive_at, :datetime unless column_exists?(:students, :archive_at)
  end
end
