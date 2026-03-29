FactoryBot.define do
  factory :campaign do
    sequence(:uid) { |n| "campaign-#{n}" }
    region { "jp" }
    category { ["exp"] }
    multiplier { 2 }
    start_at { 1.week.ago }
    end_at { 1.week.from_now }
  end
end
