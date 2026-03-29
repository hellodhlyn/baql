require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::RaidBosses::CreateRaidBoss, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateRaidBossInput!) {
        createRaidBoss(input: $input) {
          raidBoss { uid raidType }
          errors
        }
      }
    GRAPHQL
  end

  it "creates a RaidBoss" do
    result = execute_graphql_as_admin(mutation, variables: { input: { uid: "binah", raidType: "raid" } })
    data = result.dig("data", "createRaidBoss")
    expect(data["errors"]).to be_empty
    expect(data.dig("raidBoss", "uid")).to eq("binah")
    expect(RaidBoss.find_by(uid: "binah")).to be_present
  end

  it "returns an error when event_content_uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "binah", raidType: "raid", eventContentUid: "nonexistent" },
    })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end

  it "returns an error when uid is duplicated" do
    FactoryBot.create(:raid_boss, uid: "binah")
    result = execute_graphql_as_admin(mutation, variables: { input: { uid: "binah", raidType: "raid" } })
    data = result.dig("data", "createRaidBoss")
    expect(data["errors"]).to be_present
    expect(data["raidBoss"]).to be_nil
  end
end
