FactoryBot.define do
  factory :raid_schedule do
    association :raid_boss, strategy: :create
    sequence(:uid) { |n| "jp_total_assault_#{n}" }
    baql_id { "#{RaidSchedule::BAQL_ID_PREFIX}#{uid}" }
    raid_boss_uid { raid_boss.uid }
    region { "jp" }
    raid_type { "total_assault" }
    sequence(:season_index) { |n| n }
    terrain { "indoor" }
    start_at { 1.week.ago }
    end_at { 1.week.from_now }
    defense_types { [{ "defense_type" => "special", "difficulty" => "lunatic" }] }
    attack_type { "piercing" }
  end
end
