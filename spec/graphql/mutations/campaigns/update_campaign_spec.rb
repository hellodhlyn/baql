require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::Campaigns::UpdateCampaign, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateCampaignInput!) {
        updateCampaign(input: $input) {
          campaign { uid region category multiplier }
          errors
        }
      }
    GRAPHQL
  end

  let!(:campaign) { FactoryBot.create(:campaign, uid: "drop-2x", region: "jp", multiplier: 2) }

  it "updates a Campaign" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "drop-2x", region: "jp", multiplier: 3 },
    })
    data = result.dig("data", "updateCampaign")
    expect(data["errors"]).to be_empty
    expect(data.dig("campaign", "multiplier")).to eq(3)
    expect(campaign.reload.multiplier).to eq(3)
  end

  it "returns an error when uid+region does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "nonexistent", region: "jp" },
    })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end
end
