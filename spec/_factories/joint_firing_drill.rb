FactoryBot.define do
  factory :joint_firing_drill do
    sequence(:uid)    { |n| "jfd-#{n}" }
    sequence(:season) { |n| n }
    drill_type  { "shooting" }
    terrain     { "outdoor" }
    defense_type { "normal" }
    confirmed   { true }
  end
end
