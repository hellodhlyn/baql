FactoryBot.define do
  factory :raid do
    uid { "20250225-shirokuro" }
    name { "시로 & 쿠로" }
    type { "total_assault" }
    boss { "shirokuro" }
    terrain { "indoor" }
    attack_type { "piercing" }
    defense_type { nil }
    defense_types { [{ defense_type: "special", difficulty: nil }] }
    since { Time.parse("2025-02-25 02:00:00") }
    add_attribute(:until) { Time.parse("2025-03-03 19:00:00") }
  end
end
