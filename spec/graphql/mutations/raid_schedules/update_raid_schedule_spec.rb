require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::RaidSchedules::UpdateRaidSchedule, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateRaidScheduleInput!) {
        updateRaidSchedule(input: $input) {
          raidSchedule { uid seasonIndex terrain }
          errors
        }
      }
    GRAPHQL
  end

  let!(:schedule) { FactoryBot.create(:raid_schedule, uid: "jp_total_assault_10", season_index: 10, terrain: "indoor") }

  it "updates a RaidSchedule" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "jp_total_assault_10", terrain: "outdoor" },
    })
    data = result.dig("data", "updateRaidSchedule")
    expect(data["errors"]).to be_empty
    expect(data.dig("raidSchedule", "terrain")).to eq("outdoor")
    expect(schedule.reload.terrain).to eq("outdoor")
  end

  it "updates defense_types" do
    mutation_with_defense = <<~GRAPHQL
      mutation($input: UpdateRaidScheduleInput!) {
        updateRaidSchedule(input: $input) {
          raidSchedule { uid }
          errors
        }
      }
    GRAPHQL
    result = execute_graphql_as_admin(mutation_with_defense, variables: {
      input: {
        uid: "jp_total_assault_10",
        defenseTypes: [{ defenseType: "heavy", difficulty: "torment" }],
      },
    })
    data = result.dig("data", "updateRaidSchedule")
    expect(data["errors"]).to be_empty
    expect(schedule.reload.defense_types.first.defense_type).to eq("heavy")
  end

  it "returns an error when uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "nonexistent", terrain: "outdoor" },
    })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end
end
