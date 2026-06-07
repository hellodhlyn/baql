require "rails_helper"

RSpec.describe Queries::StagesQuery, type: :graphql do
  def stage_query
    <<~GRAPHQL
      query($uid: String!) {
        stage(uid: $uid) {
          uid
          category
          stageType
          difficulty
          area
          stageNumber
          terrain
          level
          name
          defenseTypes
          entryCosts {
            amount
            resource {
              type
              uid
              name
            }
          }
          starCondition {
            type
            value
          }
          challengeConditions {
            type
            value
          }
          rewards {
            rewardType
            amount
            amountMin
            amountMax
            probability
            rewardTag
            resource {
              type
              uid
              name
            }
            gachaGroup {
              uid
              items(region: gl) {
                chance
                amountMin
                amountMax
                resource {
                  type
                  uid
                  name
                }
              }
            }
          }
          glRewards: rewards(region: gl) {
            rewardType
            amount
            probability
            resource {
              type
              uid
              name
            }
          }
        }
      }
    GRAPHQL
  end

  def stages_query
    <<~GRAPHQL
      query {
        stages(category: "campaign") {
          uid
          name
          defenseTypes
          entryCosts {
            amount
            resource {
              uid
              name
            }
          }
          rewards(region: gl) {
            rewardType
            resource {
              uid
              name
            }
            gachaGroup {
              uid
              items(region: gl) {
                resource {
                  uid
                  name
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end

  def gacha_group_query
    <<~GRAPHQL
      query($uid: String!) {
        gachaGroup(uid: $uid) {
          uid
          items(region: cn) {
            chance
            amountMin
            amountMax
            resource {
              type
              uid
              name
            }
          }
        }
      }
    GRAPHQL
  end

  def create_resource_records(prefix = "")
    currency = FactoryBot.create(:currency, uid: "#{prefix}5", name: "#{prefix}AP")
    item = FactoryBot.create(:item, uid: "#{prefix}100", name: "#{prefix}Report")
    equipment = FactoryBot.create(:equipment, uid: "#{prefix}200", name: "#{prefix}Bag")
    group_item = FactoryBot.create(:item, uid: "#{prefix}300", name: "#{prefix}Gacha Item")
    cn_item = FactoryBot.create(:item, uid: "#{prefix}301", name: "#{prefix}CN Item")

    [currency, item, equipment, group_item, cn_item]
  end

  def create_gacha_group(uid: "900", prefix: "")
    FactoryBot.create(
      :gacha_group,
      uid: uid,
      raw_data: {
        "Items" => [
          { "Type" => "Item", "Id" => "#{prefix}300", "Chance" => 0.4, "AmountMin" => 1, "AmountMax" => 2 },
        ],
        "ItemsGlobal" => [
          { "Type" => "Item", "Id" => "#{prefix}300", "Chance" => 0.6, "AmountMin" => 2, "AmountMax" => 4 },
        ],
        "ItemsCn" => [
          { "Type" => "Item", "Id" => "#{prefix}301", "Chance" => 0.8, "AmountMin" => 3, "AmountMax" => 5 },
        ],
      },
    )
  end

  def create_campaign_stage(uid: "101", group_uid: "900", prefix: "")
    FactoryBot.create(
      :stage,
      uid: uid,
      name: "#{prefix}1-1",
      category: "campaign",
      stage_type: nil,
      difficulty: 0,
      area: 1,
      stage_number: "1",
      terrain: "street",
      level: 12,
      raw_data: {
        "Category" => "Campaign",
        "Difficulty" => 0,
        "Area" => 1,
        "Stage" => 1,
        "Terrain" => "Street",
        "Level" => 12,
        "EntryCost" => [["#{prefix}5", 10]],
        "StarCondition" => ["Clear", 1],
        "ChallengeCondition" => [["Turn", 5], ["Time", 120]],
        "Rewards" => [
          { "Type" => "Currency", "Id" => "#{prefix}5", "Amount" => 100, "RewardType" => "FirstClear" },
          { "Type" => "Item", "Id" => "#{prefix}100", "AmountMin" => 1, "AmountMax" => 2, "Chance" => 0.25 },
          { "Type" => "Equipment", "Id" => "#{prefix}200", "Amount" => 1, "RewardType" => "ThreeStar" },
          { "Type" => "GachaGroup", "Id" => group_uid, "Chance" => 0.5 },
        ],
        "ServerData" => {
          "Global" => {
            "Rewards" => [
              { "Type" => "Item", "Id" => "#{prefix}100", "Amount" => 3, "Chance" => 0.75 },
            ],
          },
        },
        "ArmorTypes" => ["LightArmor", "HeavyArmor", "LightArmor"],
      },
    )
  end

  def create_non_campaign_stage
    FactoryBot.create(
      :stage,
      uid: "bounty-a",
      category: "bounty",
      stage_type: "chaser_a",
      difficulty: nil,
      area: nil,
      stage_number: "A",
      terrain: "outdoor",
      level: 20,
      raw_data: {
        "Category" => "Bounty",
        "Type" => "ChaserA",
        "Stage" => "A",
        "Terrain" => "Outdoor",
        "Level" => 20,
        "EntryCost" => [],
        "StarCondition" => ["Clear", 1],
        "Rewards" => [],
        "ArmorTypes" => ["Unarmed"],
      },
    )
  end

  it "returns stages with region-aware rewards and batched nested records" do
    create_resource_records
    create_gacha_group
    create_campaign_stage
    create_non_campaign_stage

    result = execute_graphql(stage_query, variables: { uid: "101" })

    expect(result["errors"]).to be_nil
    stage = result.dig("data", "stage")
    expect(stage).to include(
      "uid" => "101",
      "category" => "campaign",
      "stageType" => nil,
      "difficulty" => 0,
      "area" => 1,
      "stageNumber" => "1",
      "terrain" => "street",
      "level" => 12,
      "name" => "1-1",
      "defenseTypes" => ["light", "heavy"],
    )
    expect(stage["entryCosts"]).to contain_exactly(
      a_hash_including("amount" => 10, "resource" => a_hash_including("type" => "currency", "uid" => "5", "name" => "AP"))
    )
    expect(stage["starCondition"]).to eq("type" => "clear", "value" => 1)
    expect(stage["challengeConditions"]).to eq([
      { "type" => "turn", "value" => 5 },
      { "type" => "time", "value" => 120 },
    ])

    rewards = stage["rewards"]
    expect(rewards).to include(
      a_hash_including(
        "rewardType" => "currency",
        "amount" => 100,
        "rewardTag" => "first_clear",
        "resource" => a_hash_including("type" => "currency", "uid" => "5", "name" => "AP"),
        "gachaGroup" => nil,
      ),
      a_hash_including(
        "rewardType" => "item",
        "amountMin" => 1,
        "amountMax" => 2,
        "probability" => 0.25,
        "resource" => a_hash_including("type" => "item", "uid" => "100", "name" => "Report"),
      ),
      a_hash_including(
        "rewardType" => "equipment",
        "amount" => 1,
        "rewardTag" => "three_star",
        "resource" => a_hash_including("type" => "equipment", "uid" => "200", "name" => "Bag"),
      ),
      a_hash_including(
        "rewardType" => "gacha_group",
        "probability" => 0.5,
        "resource" => nil,
        "gachaGroup" => a_hash_including(
          "uid" => "900",
          "items" => contain_exactly(
            a_hash_including(
              "chance" => 0.6,
              "amountMin" => 2,
              "amountMax" => 4,
              "resource" => a_hash_including("type" => "item", "uid" => "300", "name" => "Gacha Item"),
            )
          ),
        ),
      ),
    )
    expect(stage["glRewards"]).to contain_exactly(
      a_hash_including(
        "rewardType" => "item",
        "amount" => 3,
        "probability" => 0.75,
        "resource" => a_hash_including("type" => "item", "uid" => "100", "name" => "Report"),
      )
    )
  end

  it "returns non-campaign stage fields without a name" do
    create_non_campaign_stage

    result = execute_graphql(stage_query, variables: { uid: "bounty-a" })

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "stage")).to include(
      "uid" => "bounty-a",
      "category" => "bounty",
      "stageType" => "chaser_a",
      "difficulty" => nil,
      "area" => nil,
      "stageNumber" => "A",
      "terrain" => "outdoor",
      "level" => 20,
      "name" => nil,
      "defenseTypes" => ["special"],
    )
  end

  it "returns a gacha group with region-specific items" do
    create_resource_records
    create_gacha_group

    result = execute_graphql(gacha_group_query, variables: { uid: "900" })

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "gachaGroup")).to include(
      "uid" => "900",
      "items" => contain_exactly(
        a_hash_including(
          "chance" => 0.8,
          "amountMin" => 3,
          "amountMax" => 5,
          "resource" => a_hash_including("type" => "item", "uid" => "301", "name" => "CN Item"),
        )
      ),
    )
  end

  it "does not grow SQL count with the number of stages" do
    2.times do |index|
      prefix = "n#{index}-"
      create_resource_records(prefix)
      create_gacha_group(uid: "group-#{index}", prefix: prefix)
      create_campaign_stage(uid: "stage-#{index}", group_uid: "group-#{index}", prefix: prefix)
    end

    result, queries = capture_sql do
      execute_graphql(stages_query)
    end

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "stages").size).to eq(2)

    4.times do |index|
      prefix = "m#{index}-"
      create_resource_records(prefix)
      create_gacha_group(uid: "more-group-#{index}", prefix: prefix)
      create_campaign_stage(uid: "more-stage-#{index}", group_uid: "more-group-#{index}", prefix: prefix)
    end

    result_with_more_stages, queries_with_more_stages = capture_sql do
      execute_graphql(stages_query)
    end

    expect(result_with_more_stages["errors"]).to be_nil
    expect(result_with_more_stages.dig("data", "stages").size).to eq(6)
    expect(queries_with_more_stages.size).to eq(queries.size)
  end
end
