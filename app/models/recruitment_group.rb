class RecruitmentGroup < ApplicationRecord
  BAQL_ID_PREFIX = "baql::recruitment_groups::"
  CONTENT_TYPES = ["event_content", "main_story_part"].freeze

  has_many :recruitments, primary_key: :uid, foreign_key: :recruitment_group_uid

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :content_type, inclusion: { in: CONTENT_TYPES }, allow_nil: true

  def content
    case content_type
    when "event_content" then EventContent.find_by(uid: content_uid)
    when "main_story_part" then MainStoryPart.find_by(uid: content_uid)
    end
  end
end
