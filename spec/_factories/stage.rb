FactoryBot.define do
  factory :stage do
    sequence(:uid) { |n| "stage-#{n}" }
    baql_id { "#{Stage::BAQL_ID_PREFIX}#{uid}" }
    category { "campaign" }
    stage_type { nil }
    difficulty { 0 }
    area { 1 }
    stage_number { "1" }
    terrain { "street" }
    level { 10 }
    raw_data do
      {
        "Category" => "Campaign",
        "Stage" => 1,
        "Terrain" => "Street",
        "Level" => 10,
        "EntryCost" => [],
        "StarCondition" => ["Clear", 1],
        "ChallengeCondition" => [],
        "Rewards" => [],
        "ArmorTypes" => ["LightArmor"],
      }
    end

    transient do
      name { nil }
    end

    after(:create) do |stage, evaluator|
      stage.set_name(evaluator.name, "ko") if evaluator.name
    end
  end
end
