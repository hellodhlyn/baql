# frozen_string_literal: true

class MiniStorySchedule < ApplicationRecord
  belongs_to :mini_story, foreign_key: :mini_story_uid, primary_key: :uid

  validates :region, inclusion: { in: Constants::REGIONS }
  validates :released_at, presence: true
  validates :mini_story_uid, uniqueness: { scope: :region }
end
