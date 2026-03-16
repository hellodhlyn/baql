FactoryBot.define do
  factory :item do
    sequence(:uid) { |n| n.to_s }
    baql_id { "baql::items::#{uid}" }
    category { "material" }
    rarity { 2 }
    raw_data { {} }

    transient do
      name { nil }
    end

    after(:create) do |item, evaluator|
      item.set_name(evaluator.name, "ko") if evaluator.name
    end
  end
end
