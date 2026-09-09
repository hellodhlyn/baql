FactoryBot.define do
  factory :event_content_run do
    association :event_content, strategy: :create
    event_content_uid { event_content.uid }
    run_type { "first" }
    sequence(:source_event_content_uid) { |n| n }
    sequence(:position) { |n| n }
  end
end
