require "rails_helper"

RSpec.describe "RaidSchedule defense type sets", type: :graphql do
  it "returns grouped defense type sets and legacy flattened defense types" do
    boss = FactoryBot.create(:raid_boss, uid: "drumbarka", raid_type: "raid")
    FactoryBot.create(
      :raid_schedule,
      raid_boss: boss,
      uid: "jp_total_assault_90",
      season_index: 90,
      defense_types: [
        { "defense_types" => ["light", "special"], "difficulty" => "lunatic" },
      ],
    )

    query = <<~GRAPHQL
      query {
        raidSchedule(uid: "jp_total_assault_90") {
          defenseTypeSets {
            defenseTypes
            difficulty
          }
          defenseTypes {
            defenseType
            difficulty
          }
        }
      }
    GRAPHQL

    result = execute_graphql(query)
    schedule = result.dig("data", "raidSchedule")

    expect(schedule["defenseTypeSets"]).to eq([
      { "defenseTypes" => ["light", "special"], "difficulty" => "lunatic" },
    ])
    expect(schedule["defenseTypes"]).to contain_exactly(
      { "defenseType" => "light", "difficulty" => "lunatic" },
      { "defenseType" => "special", "difficulty" => "lunatic" },
    )
  end
end
