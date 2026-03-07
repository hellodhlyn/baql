FactoryBot.define do
  factory :main_story_volume do
    sequence(:uid) { |n| n.to_s }
    baql_id { "#{MainStoryVolume::BAQL_ID_PREFIX}#{uid}" }
    label { "Vol.#{uid}" }
    sequence(:sort_order) { |n| n }
  end

  factory :main_story_chapter do
    sequence(:uid) { |n| "1-#{n}" }
    baql_id { "#{MainStoryChapter::BAQL_ID_PREFIX}#{uid}" }
    volume_uid { FactoryBot.create(:main_story_volume).uid }
    sequence(:chapter_number) { |n| n }
  end

  factory :main_story_part do
    sequence(:uid) { |n| "1-1-#{n}" }
    baql_id { "#{MainStoryPart::BAQL_ID_PREFIX}#{uid}" }
    chapter_uid { FactoryBot.create(:main_story_chapter).uid }
    sequence(:sort_order) { |n| n }
  end
end
