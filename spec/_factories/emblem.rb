FactoryBot.define do
  factory :emblem do
    sequence(:uid) { |n| n.to_s }
    baql_id { "#{Emblem::BAQL_ID_PREFIX}#{uid}" }
    category { "mission" }
    rarity { 1 }
    raw_data { {} }
    image_asset_keys { {} }

    transient do
      name { nil }
      description { nil }
    end

    after(:create) do |emblem, evaluator|
      emblem.set_name(evaluator.name, "ko") if evaluator.name
      emblem.set_description(evaluator.description, "ko") if evaluator.description
    end
  end
end
