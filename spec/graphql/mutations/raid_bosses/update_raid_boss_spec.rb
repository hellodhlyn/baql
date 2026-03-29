require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::RaidBosses::UpdateRaidBoss, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateRaidBossInput!) {
        updateRaidBoss(input: $input) {
          raidBoss { uid raidType }
          errors
        }
      }
    GRAPHQL
  end

  let!(:boss) { FactoryBot.create(:raid_boss, uid: "binah", raid_type: "raid") }

  it "updates a RaidBoss" do
    result = execute_graphql_as_admin(mutation, variables: { input: { uid: "binah", raidType: "unlimit" } })
    data = result.dig("data", "updateRaidBoss")
    expect(data["errors"]).to be_empty
    expect(data.dig("raidBoss", "raidType")).to eq("unlimit")
    expect(boss.reload.raid_type).to eq("unlimit")
  end

  it "returns an error when uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: { input: { uid: "nonexistent" } })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end
end
