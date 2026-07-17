require "rails_helper"

RSpec.describe Maintenance::GlScheduleShift do
  describe "#call" do
    let(:cutoff) { Time.zone.parse("2026-06-02 00:00:00") }
    let(:shift_by) { 7.days }

    it "shifts GL schedules, recruitment groups, and affected student release dates" do
      event_schedule = FactoryBot.create(
        :event_content_schedule,
        region: "gl",
        start_at: cutoff,
        end_at: cutoff + 14.days,
      )
      jp_event_schedule = FactoryBot.create(
        :event_content_schedule,
        region: "jp",
        start_at: cutoff,
        end_at: cutoff + 14.days,
        run_type: "rerun",
      )
      old_recruitment_group = FactoryBot.create(
        :recruitment_group,
        start_at: cutoff - 14.days,
        end_at: cutoff - 7.days,
      )
      recruitment_group = FactoryBot.create(
        :recruitment_group,
        start_at: cutoff + 1.day,
        end_at: cutoff + 15.days,
      )
      affected_student = FactoryBot.create(:student, uid: "student-1", release_at: recruitment_group.start_at)
      unaffected_student = FactoryBot.create(:student, uid: "student-2", release_at: Time.zone.parse("2020-01-01 00:00:00"))
      FactoryBot.create(:recruitment, recruitment_group_uid: recruitment_group.uid, student_uid: affected_student.uid)
      FactoryBot.create(:recruitment, recruitment_group_uid: old_recruitment_group.uid, student_uid: unaffected_student.uid)
      FactoryBot.create(:recruitment, recruitment_group_uid: recruitment_group.uid, student_uid: unaffected_student.uid)

      result = described_class.new(cutoff: cutoff, shift_by: shift_by, dry_run: false).call

      expect(result.total_rows).to eq(2)
      expect(event_schedule.reload.start_at).to eq(cutoff + shift_by)
      expect(event_schedule.end_at).to eq(cutoff + 14.days + shift_by)
      expect(jp_event_schedule.reload.start_at).to eq(cutoff)
      expect(recruitment_group.reload.start_at).to eq(cutoff + 1.day + shift_by)
      expect(recruitment_group.end_at).to eq(cutoff + 15.days + shift_by)
      expect(old_recruitment_group.reload.start_at).to eq(cutoff - 14.days)
      expect(affected_student.reload.release_at).to eq(recruitment_group.start_at)
      expect(unaffected_student.reload.release_at).to eq(old_recruitment_group.start_at)
    end

    it "rolls back changes in dry-run mode" do
      recruitment_group = FactoryBot.create(
        :recruitment_group,
        start_at: cutoff,
        end_at: cutoff + 14.days,
      )
      student = FactoryBot.create(:student, uid: "student-3", release_at: recruitment_group.start_at)
      FactoryBot.create(:recruitment, recruitment_group_uid: recruitment_group.uid, student_uid: student.uid)

      result = described_class.new(cutoff: cutoff, shift_by: shift_by, dry_run: true).call

      expect(result.total_rows).to eq(1)
      expect(result.student_release_updates.size).to eq(1)
      expect(recruitment_group.reload.start_at).to eq(cutoff)
      expect(student.reload.release_at).to eq(cutoff)
    end

    it "shifts GL mini story schedules" do
      schedule = FactoryBot.create(
        :mini_story_schedule,
        region: "gl",
        released_at: cutoff,
      )

      result = described_class.new(cutoff: cutoff, shift_by: -shift_by, dry_run: false).call

      expect(result.total_rows).to eq(1)
      expect(schedule.reload.released_at).to eq(cutoff - shift_by)
      expect(result.schedule_updates).to contain_exactly(
        have_attributes(
          label: "mini_story_schedules",
          identifier: "mini_story_uid=#{schedule.mini_story_uid}",
        ),
      )
    end

    it "reports when the synced first recruitment is not one of the shifted groups" do
      shifted_group = FactoryBot.create(
        :recruitment_group,
        start_at: cutoff,
        end_at: cutoff + 14.days,
      )
      unshifted_group = FactoryBot.create(
        :recruitment_group,
        start_at: cutoff - 1.day,
        end_at: cutoff + 15.days,
      )
      student = FactoryBot.create(:student, uid: "student-4", release_at: shifted_group.start_at)
      FactoryBot.create(:recruitment, recruitment_group_uid: shifted_group.uid, student_uid: student.uid)
      FactoryBot.create(:recruitment, recruitment_group_uid: unshifted_group.uid, student_uid: student.uid)
      student.update_column(:release_at, shifted_group.start_at)
      expect(student.reload.release_at).to eq(shifted_group.start_at)

      result = described_class.new(cutoff: cutoff, shift_by: shift_by, dry_run: false).call

      expect(student.reload.release_at).to eq(unshifted_group.start_at)
      expect(result.student_release_updates).to contain_exactly(
        have_attributes(
          uid: student.uid,
          recruitment_group_uid: shifted_group.uid,
          before: { release_at: cutoff, archive_at: nil },
          after: { release_at: unshifted_group.start_at, archive_at: nil },
        ),
      )
    end

    it "reports archive_at changes even when release_at is unchanged" do
      first_group = FactoryBot.create(
        :recruitment_group,
        start_at: cutoff - 7.days,
        end_at: cutoff - 1.day,
      )
      archive_group = FactoryBot.create(
        :recruitment_group,
        start_at: cutoff,
        end_at: cutoff + 14.days,
      )
      student = FactoryBot.create(:student, uid: "student-5", release_at: nil, archive_at: nil)
      FactoryBot.create(:recruitment, recruitment_group_uid: first_group.uid, student_uid: student.uid, recruitment_type: "limited")
      FactoryBot.create(:recruitment, recruitment_group_uid: archive_group.uid, student_uid: student.uid, recruitment_type: "archive")

      result = described_class.new(cutoff: cutoff, shift_by: shift_by, dry_run: false).call

      expect(student.reload.release_at).to eq(first_group.start_at)
      expect(student.archive_at).to eq(archive_group.reload.start_at)
      expect(result.student_release_updates).to contain_exactly(
        have_attributes(
          uid: student.uid,
          recruitment_group_uid: archive_group.uid,
          before: { release_at: first_group.start_at, archive_at: cutoff },
          after: { release_at: first_group.start_at, archive_at: cutoff + shift_by },
        ),
      )
    end
  end
end
