require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::Campaigns::CreateCampaign, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateCampaignInput!) {
        createCampaign(input: $input) {
          campaign { uid region category multiplier }
          errors
        }
      }
    GRAPHQL
  end

  it "creates a Campaign" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "drop-2x",
        region: "jp",
        category: ["exp"],
        multiplier: 2,
        startAt: "2026-04-01T00:00:00Z",
        endAt: "2026-04-15T00:00:00Z",
      },
    })
    data = result.dig("data", "createCampaign")
    expect(data["errors"]).to be_empty
    expect(data.dig("campaign", "uid")).to eq("drop-2x")
    expect(data.dig("campaign", "region")).to eq("jp")
    expect(data.dig("campaign", "category")).to eq(["exp"])
    expect(Campaign.find_by(uid: "drop-2x", region: "jp")).to be_present
  end

  it "returns validation errors for invalid multiplier" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "drop-1x",
        region: "jp",
        category: ["exp"],
        multiplier: 1,
        startAt: "2026-04-01T00:00:00Z",
        endAt: "2026-04-15T00:00:00Z",
      },
    })
    data = result.dig("data", "createCampaign")
    expect(data["errors"]).to be_present
    expect(data["campaign"]).to be_nil
  end

  it "returns an error when uid+region is duplicated" do
    FactoryBot.create(:campaign, uid: "drop-2x", region: "jp")
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "drop-2x",
        region: "jp",
        category: ["exp"],
        multiplier: 2,
        startAt: "2026-04-01T00:00:00Z",
        endAt: "2026-04-15T00:00:00Z",
      },
    })
    data = result.dig("data", "createCampaign")
    expect(data["errors"]).to be_present
    expect(data["campaign"]).to be_nil
  end
end
