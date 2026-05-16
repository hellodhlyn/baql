class RecruitmentGroup < ApplicationRecord
  BAQL_ID_PREFIX = "baql::recruitment_groups::"
  CONTENT_TYPES = ["event_content", "main_story_part"].freeze

  has_many :recruitments, primary_key: :uid, foreign_key: :recruitment_group_uid

  after_save :sync_student_recruitment_dates, if: :saved_change_to_start_at?

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :content_type,     inclusion: { in: CONTENT_TYPES },               allow_nil: true
  validates :recruitment_type, presence: true, inclusion: { in: Recruitment::RECRUITMENT_TYPES }

  def content
    case content_type
    when "event_content" then EventContent.find_by(uid: content_uid)
    when "main_story_part" then MainStoryPart.find_by(uid: content_uid)
    end
  end

  private

  def sync_student_recruitment_dates
    Student.sync_recruitment_dates!(recruitments.where.not(student_uid: nil).distinct.pluck(:student_uid))
  end
end
