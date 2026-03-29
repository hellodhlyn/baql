require "rails_helper"

# frozen_string_literal: true

RSpec.describe "Mutation authentication", type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation {
        createRaidBoss(input: { uid: "test-boss", raidType: raid }) {
          raidBoss { uid }
          errors
        }
      }
    GRAPHQL
  end

  it "returns an error when called without authentication" do
    result = execute_graphql(mutation)
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("Authentication required")
  end

  it "executes the mutation when admin context is present" do
    result = execute_graphql_as_admin(mutation)
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "createRaidBoss", "errors")).to be_empty
  end
end
