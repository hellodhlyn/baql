FactoryBot.define do
  factory :equipment do
    sequence(:uid) { |n| "equipment-#{n}" }
    baql_id { "#{Equipment::BAQL_ID_PREFIX}#{uid}" }
    category { "exp" }
    rarity { 2 }
    raw_data { {} }

    transient do
      name { nil }
    end

    after(:create) do |equipment, evaluator|
      equipment.set_name(evaluator.name, "ko") if evaluator.name
    end
  end
end
