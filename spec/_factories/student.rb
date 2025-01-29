FactoryBot.define do
  factory :student do
    student_id { "13005" }
    name { "카요코" }
    school { "gehenna" }
    initial_tier { 2 }
    attack_type { "explosive" }
    defense_type { "heavy" }
    role { "striker" }
    equipments { ["shoes", "hairpin", "necklace"] }
    release_at { nil }
    order { 19 }
  end
end
