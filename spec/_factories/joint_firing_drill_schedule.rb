FactoryBot.define do
  factory :joint_firing_drill_schedule do
    association :drill, factory: :joint_firing_drill, strategy: :create
    drill_uid { drill.uid }
    region    { "jp" }
    start_at  { 1.week.ago }
    end_at    { 1.week.from_now }
  end
end
