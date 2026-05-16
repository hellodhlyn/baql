class BackfillStudentRecruitmentDates < ActiveRecord::Migration[8.0]
  def up
    student_uids = Recruitment.where.not(student_uid: nil).distinct.pluck(:student_uid)
    Student.sync_recruitment_dates!(student_uids)
  end

  def down
    # Existing values were recalculated from mutable recruitment rows.
  end
end
