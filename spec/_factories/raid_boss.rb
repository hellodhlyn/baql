FactoryBot.define do
  factory :raid_boss do
    sequence(:uid) { |n| "boss-#{n}" }
    baql_id { "#{RaidBoss::BAQL_ID_PREFIX}#{uid}" }
    raid_type { "raid" }
    event_content_uid { nil }
  end
end
