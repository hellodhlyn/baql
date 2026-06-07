FactoryBot.define do
  factory :gacha_group do
    sequence(:uid) { |n| "group-#{n}" }
    baql_id { "#{GachaGroup::BAQL_ID_PREFIX}#{uid}" }
    raw_data do
      {
        "Items" => [],
      }
    end
  end
end
