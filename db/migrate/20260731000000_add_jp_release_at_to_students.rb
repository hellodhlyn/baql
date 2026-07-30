class AddJpReleaseAtToStudents < ActiveRecord::Migration[8.0]
  def change
    add_column :students, :jp_release_at, :datetime
    add_index :students, :jp_release_at
  end
end
