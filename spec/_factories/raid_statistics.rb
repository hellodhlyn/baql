FactoryBot.define do
  factory :raid_statistics do
    association :raid
    student_id { "13005" }
    defense_type { "special" }
    difficulty { "torment" }
    counts_by_tier { { "7" => 39, "8" => 42 } }
  end
end
