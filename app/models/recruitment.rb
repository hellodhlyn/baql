class Recruitment < ApplicationRecord
  BAQL_ID_PREFIX = "baql::recruitments::"
  RECRUITMENT_TYPES = ["given", "usual", "limited", "fes", "archive", "encore", "recollect"].freeze
  ARCHIVE_RECRUITMENT_TYPES = ["archive", "encore", "recollect"].freeze

  belongs_to :recruitment_group, primary_key: :uid, foreign_key: :recruitment_group_uid
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid, optional: true

  delegate :start_at, to: :recruitment_group
  delegate :end_at, to: :recruitment_group

  after_save :sync_student_recruitment_dates, if: :saved_change_affecting_student_recruitment_dates?

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :student_name, presence: true
  validates :recruitment_type, presence: true, inclusion: { in: RECRUITMENT_TYPES }

  private

  def sync_student_recruitment_dates
    Student.sync_recruitment_dates!(student_uids_for_recruitment_date_sync)
  end

  def student_uids_for_recruitment_date_sync
    [student_uid_before_last_save, student_uid].compact.uniq
  end

  def saved_change_affecting_student_recruitment_dates?
    saved_change_to_student_uid? ||
      saved_change_to_recruitment_type? ||
      saved_change_to_recruitment_group_uid?
  end
end
