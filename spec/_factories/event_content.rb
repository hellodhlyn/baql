FactoryBot.define do
  factory :event_content do
    sequence(:uid) { |n| "ec-#{n}" }
    baql_id { "#{EventContent::BAQL_ID_PREFIX}#{uid}" }
  end
end
