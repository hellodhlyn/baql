FactoryBot.define do
  factory :raid_statistics do
    association :raid
    student { FactoryBot.create(:student, uid: (10000...30000).to_a.sample.to_s) }
    defense_type { "special" }
    difficulty { "torment" }
    slots_count { 39 + 42 }
    slots_by_tier { { "7" => 39, "8" => 42 } }
    assists_count { 39 + 42 }
    assists_by_tier { { "7" => 39, "8" => 42 } }
  end
end
