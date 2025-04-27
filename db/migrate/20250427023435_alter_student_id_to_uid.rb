class AlterStudentIdToUid < ActiveRecord::Migration[8.0]
  def change
    rename_column :students, :student_id, :uid
    rename_column :students, :multiclass_id, :multiclass_uid
    rename_column :raid_statistics, :student_id, :student_uid

    Event.all.each do |event|
      pickups = event.read_attribute(:pickups)
      next if pickups.blank?

      event.update!(pickups: pickups.map { |pickup| pickup["studentUid"] = pickup["studentId"]; pickup })
    end
  end
end
