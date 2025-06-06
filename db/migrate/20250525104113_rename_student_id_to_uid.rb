class RenameStudentIdToUid < ActiveRecord::Migration[8.0]
  def change
    rename_column :students, :student_id, :uid
    rename_column :students, :multiclass_id, :multiclass_uid
    rename_column :raid_statistics, :student_id, :student_uid
  end
end
