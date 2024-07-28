class AddMulticlassIdToStudents < ActiveRecord::Migration[7.1]
  def change
    add_column :students, :multiclass_id, :string
  end
end
