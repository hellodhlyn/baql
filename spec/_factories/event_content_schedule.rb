FactoryBot.define do
  factory :event_content_schedule do
    association :event_content, strategy: :create
    event_content_uid { event_content.uid }
    region { "jp" }
    run_type { "first" }
    start_at { 1.week.ago }
    end_at { 1.week.from_now }
  end
end
