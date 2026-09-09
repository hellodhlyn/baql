FactoryBot.define do
  factory :event_content_run_mission do
    association :event_content_run, strategy: :create
    sequence(:uid) { |n| "mission-#{n}" }
    category { "event_achievement" }
    reset_type { "none" }
    sequence(:display_order) { |n| n }
    sequence(:position) { |n| n }
    localizations do
      {
        "ko" => { "template" => "미션", "parameters" => [] },
        "ja" => { "template" => "ミッション", "parameters" => [] },
      }
    end
    condition_type { "reset_complete_stage" }
    condition_count { 1 }
    condition_parameters { [] }
    condition_parameter_tags { [] }
    reward_type { "currency" }
    reward_uid { "1" }
    reward_amount { 1 }
    condition_reward_type { nil }
    condition_reward_uid { nil }
    condition_reward_amount { nil }
    pre_mission_uid { nil }
    completion_reference_mission_uid { nil }
    completion_reference_required_count { 0 }
    completion_extension { false }
  end
end
