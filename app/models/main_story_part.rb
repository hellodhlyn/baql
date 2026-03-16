class MainStoryPart < ApplicationRecord
  include Translatable

  belongs_to :chapter, class_name: "MainStoryChapter", foreign_key: :chapter_uid, primary_key: :uid
  has_many :schedules, class_name: "MainStoryPartSchedule", foreign_key: :part_uid, primary_key: :uid

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :sort_order, presence: true
  validates :episode_start, numericality: { only_integer: true }, allow_nil: true
  validates :episode_end, numericality: { only_integer: true }, allow_nil: true

  BAQL_ID_PREFIX = "baql::main_story_parts::"

  translatable :name

  def translation_key_prefix
    baql_id
  end
end
