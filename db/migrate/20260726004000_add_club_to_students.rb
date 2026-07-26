class AddClubToStudents < ActiveRecord::Migration[8.0]
  def change
    add_column :students, :club, :string
  end
end
