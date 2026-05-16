require "rails_helper"

RSpec.describe Recruitment, type: :model do
  describe "student recruitment date sync" do
    it "updates the student's dates after create" do
      student = FactoryBot.create(:student, uid: "student-1", release_at: nil, archive_at: nil)
      group = FactoryBot.create(:recruitment_group, start_at: Time.zone.parse("2026-04-01 02:00:00"))

      FactoryBot.create(
        :recruitment,
        recruitment_group_uid: group.uid,
        student_uid: student.uid,
        recruitment_type: "archive",
      )

      expect(student.reload.release_at).to eq(group.start_at)
      expect(student.archive_at).to eq(group.start_at)
    end

    it "updates dates for both previous and current students after update" do
      old_student = FactoryBot.create(:student, uid: "old-student", release_at: nil, archive_at: nil)
      new_student = FactoryBot.create(:student, uid: "new-student", release_at: nil, archive_at: nil)
      group = FactoryBot.create(:recruitment_group, start_at: Time.zone.parse("2026-04-01 02:00:00"))
      recruitment = FactoryBot.create(
        :recruitment,
        recruitment_group_uid: group.uid,
        student_uid: old_student.uid,
        recruitment_type: "limited",
      )

      recruitment.update!(student_uid: new_student.uid, recruitment_type: "archive")

      expect(old_student.reload.release_at).to be_nil
      expect(old_student.archive_at).to be_nil
      expect(new_student.reload.release_at).to eq(group.start_at)
      expect(new_student.archive_at).to eq(group.start_at)
    end

    it "does not sync dates after unrelated fields change" do
      recruitment = FactoryBot.create(:recruitment, student_uid: nil, student_name: "카요코")

      expect(Student).not_to receive(:sync_recruitment_dates!)

      recruitment.update!(student_name: "치나츠")
    end
  end
end
