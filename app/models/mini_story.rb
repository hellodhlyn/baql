# frozen_string_literal: true

class MiniStory < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::mini_stories::"

  has_many :schedules, class_name: "MiniStorySchedule", foreign_key: :mini_story_uid, primary_key: :uid

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :episode_count, numericality: { only_integer: true, greater_than: 0 }

  translatable :title

  def translation_key_prefix
    baql_id
  end
end
