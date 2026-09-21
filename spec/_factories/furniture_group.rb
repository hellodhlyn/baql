FactoryBot.define do
  factory :furniture_group do
    sequence(:uid) { |n| "furniture-group-#{n}" }
    baql_id { "#{FurnitureGroup::BAQL_ID_PREFIX}#{uid}" }

    transient do
      name { nil }
      description { nil }
    end

    after(:create) do |furniture_group, evaluator|
      furniture_group.set_name(evaluator.name, "ko") if evaluator.name
      furniture_group.set_description(evaluator.description, "ko") if evaluator.description
    end
  end
end
