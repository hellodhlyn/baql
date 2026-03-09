class Recruitment < ApplicationRecord
  BAQL_ID_PREFIX = "baql::recruitments::"
  RECRUITMENT_TYPES = ["given", "usual", "limited", "fes", "archive", "encore", "recollect"].freeze

  belongs_to :recruitment_group, primary_key: :uid, foreign_key: :recruitment_group_uid
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid, optional: true

  delegate :start_at, to: :recruitment_group
  delegate :end_at, to: :recruitment_group

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :student_name, presence: true
  validates :recruitment_type, presence: true, inclusion: { in: RECRUITMENT_TYPES }
end
