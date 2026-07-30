FactoryBot.define do
  factory :student do
    uid { "13005" }
    character_group_uid { uid }
    student_variant_uid { uid }
    name { "카요코" }
    school { "gehenna" }
    initial_tier { 2 }
    attack_type { "explosive" }
    defense_type { "heavy" }
    role { "striker" }
    equipments { ["shoes", "hairpin", "necklace"] }
    release_at { nil }
    jp_release_at { Time.zone.parse("2021-02-14 11:00:00 +09:00") }
    order { 19 }
  end
end
