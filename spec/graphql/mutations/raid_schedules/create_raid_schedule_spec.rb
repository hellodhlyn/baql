require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::RaidSchedules::CreateRaidSchedule, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateRaidScheduleInput!) {
        createRaidSchedule(input: $input) {
          raidSchedule { uid region raidType seasonIndex terrain }
          errors
        }
      }
    GRAPHQL
  end

  let!(:boss) { FactoryBot.create(:raid_boss, uid: "binah", raid_type: "raid") }

  it "creates a RaidSchedule" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "jp_total_assault_100",
        raidBossUid: "binah",
        region: "jp",
        raidType: "total_assault",
        seasonIndex: 100,
        terrain: "indoor",
      },
    })
    data = result.dig("data", "createRaidSchedule")
    expect(data["errors"]).to be_empty
    expect(data.dig("raidSchedule", "uid")).to eq("jp_total_assault_100")
    expect(RaidSchedule.find_by(uid: "jp_total_assault_100")).to be_present
  end

  it "creates with grouped defense_type_sets" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "jp_total_assault_90",
        raidBossUid: "binah",
        region: "jp",
        raidType: "total_assault",
        seasonIndex: 90,
        terrain: "outdoor",
        defenseTypeSets: [
          { defenseTypes: ["light", "special"], difficulty: "lunatic" },
        ],
      },
    })

    data = result.dig("data", "createRaidSchedule")
    expect(data["errors"]).to be_empty
    schedule = RaidSchedule.find_by(uid: "jp_total_assault_90")
    expect(schedule.read_attribute(:defense_types)).to eq([
      { "defense_types" => ["light", "special"], "difficulty" => "lunatic" },
    ])
  end

  it "returns an error when uid is duplicated" do
    FactoryBot.create(:raid_schedule, uid: "jp_total_assault_100", raid_boss: boss, season_index: 100)
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "jp_total_assault_100",
        raidBossUid: "binah",
        region: "jp",
        raidType: "total_assault",
        seasonIndex: 101,
        terrain: "indoor",
      },
    })
    data = result.dig("data", "createRaidSchedule")
    expect(data["errors"]).to be_present
    expect(data["raidSchedule"]).to be_nil
  end
end
