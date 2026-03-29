require "rails_helper"

# frozen_string_literal: true

RSpec.describe "GraphQL admin authentication via HTTP header", type: :request do
  let(:mutation) do
    <<~GRAPHQL
      mutation {
        createEventContent(input: { uid: "auth-test-001" }) {
          eventContent { uid }
          errors
        }
      }
    GRAPHQL
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_API_KEY").and_return("test-secret-key")
  end

  it "succeeds with a valid Bearer token" do
    post "/graphql",
      params: { query: mutation }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer test-secret-key",
      }

    json = JSON.parse(response.body)
    expect(json["errors"]).to be_nil
    expect(json.dig("data", "createEventContent", "eventContent", "uid")).to eq("auth-test-001")
  end

  it "returns Authentication required error when no token is provided" do
    post "/graphql",
      params: { query: mutation }.to_json,
      headers: { "Content-Type" => "application/json" }

    json = JSON.parse(response.body)
    expect(json["errors"]).to be_present
    expect(json["errors"].first["message"]).to include("Authentication required")
  end

  it "returns Authentication required error when the token is incorrect" do
    post "/graphql",
      params: { query: mutation }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer wrong-key",
      }

    json = JSON.parse(response.body)
    expect(json["errors"]).to be_present
    expect(json["errors"].first["message"]).to include("Authentication required")
  end
end
