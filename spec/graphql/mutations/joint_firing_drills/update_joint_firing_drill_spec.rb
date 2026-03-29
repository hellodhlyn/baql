require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::JointFiringDrills::UpdateJointFiringDrill, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateJointFiringDrillInput!) {
        updateJointFiringDrill(input: $input) {
          jointFiringDrill { uid drillType terrain defenseType confirmed }
          errors
        }
      }
    GRAPHQL
  end

  let!(:drill) { FactoryBot.create(:joint_firing_drill, uid: "jfd-1", season: 1, drill_type: "shooting") }

  it "updates a JointFiringDrill" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "jfd-1", drillType: "defense" },
    })
    data = result.dig("data", "updateJointFiringDrill")
    expect(data["errors"]).to be_empty
    expect(data.dig("jointFiringDrill", "drillType")).to eq("defense")
    expect(drill.reload.drill_type).to eq("defense")
  end

  it "returns an error when uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "nonexistent" },
    })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end
end
