FactoryBot.define do
  factory :currency do
    sequence(:uid) { |n| "currency-#{n}" }
    baql_id { "#{Currency::BAQL_ID_PREFIX}#{uid}" }
    rarity { 1 }
    raw_data { {} }

    transient do
      name { nil }
    end

    after(:create) do |currency, evaluator|
      currency.set_name(evaluator.name, "ko") if evaluator.name
    end
  end
end
