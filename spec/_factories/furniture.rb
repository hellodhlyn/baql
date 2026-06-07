FactoryBot.define do
  factory :furniture do
    sequence(:uid) { |n| "furniture-#{n}" }
    baql_id { "#{Furniture::BAQL_ID_PREFIX}#{uid}" }
    category { "furniture" }
    rarity { 2 }
    tags { [] }
    raw_data { {} }

    transient do
      name { nil }
    end

    after(:create) do |furniture, evaluator|
      furniture.set_name(evaluator.name, "ko") if evaluator.name
    end
  end
end
