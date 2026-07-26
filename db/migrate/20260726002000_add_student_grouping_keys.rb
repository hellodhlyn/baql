class AddStudentGroupingKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :students, :character_group_uid, :string
    add_column :students, :student_variant_uid, :string

    add_index :students, :character_group_uid
    add_index :students, :student_variant_uid
  end
end
