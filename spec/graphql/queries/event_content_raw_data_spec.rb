require "rails_helper"

# frozen_string_literal: true

RSpec.describe "EventContent raw data access control", type: :graphql do
  let(:raw_first) { { "stages" => [{ "id" => 1 }] } }
  let!(:event_content) { FactoryBot.create(:event_content, uid: "99999", raw_data_first: raw_first) }

  let(:query) do
    <<~GRAPHQL
      query($uid: String!) {
        eventContent(uid: $uid) {
          uid
          rawDataFirst
          rawDataRerun
        }
      }
    GRAPHQL
  end

  it "returns raw data for admin" do
    result = execute_graphql_as_admin(query, variables: { uid: "99999" })
    data = result.dig("data", "eventContent")
    expect(data["rawDataFirst"]).to eq(raw_first)
    expect(data["rawDataRerun"]).to be_nil
  end

  it "returns an error when accessing raw data without authentication" do
    result = execute_graphql(query, variables: { uid: "99999" })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("Authentication required")
  end

  it "responds normally without authentication when raw data is not requested" do
    safe_query = <<~GRAPHQL
      query($uid: String!) {
        eventContent(uid: $uid) {
          uid
        }
      }
    GRAPHQL
    result = execute_graphql(safe_query, variables: { uid: "99999" })
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "eventContent", "uid")).to eq("99999")
  end
end
