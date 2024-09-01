class AddSchaleDBIdToStudents < ActiveRecord::Migration[7.2]
  def change
    add_column :students, :schale_db_id, :string
  end
end
