# frozen_string_literal: true

FactoryBot.define do
  factory :mini_story do
    sequence(:uid) { |n| "mini-story-#{n}" }
    baql_id { "#{MiniStory::BAQL_ID_PREFIX}#{uid}" }
    episode_count { 3 }

    after(:create) do |mini_story|
      mini_story.set_title("미니 스토리 #{mini_story.uid}", "ko")
    end
  end

  factory :mini_story_schedule do
    mini_story_uid { FactoryBot.create(:mini_story).uid }
    region { "jp" }
    released_at { Time.zone.parse("2026-04-01 02:00:00") }
  end
end
