class AddNameFieldsToStudents < ActiveRecord::Migration[8.0]
  def change
    add_column :students, :family_name, :string
    add_column :students, :personal_name, :string
  end
end
