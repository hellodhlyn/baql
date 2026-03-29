require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::EventContents::CreateEventContent, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateEventContentInput!) {
        createEventContent(input: $input) {
          eventContent { uid }
          errors
        }
      }
    GRAPHQL
  end

  it "creates an EventContent" do
    result = execute_graphql_as_admin(mutation, variables: { input: { uid: "99999" } })
    data = result.dig("data", "createEventContent")
    expect(data["errors"]).to be_empty
    expect(data.dig("eventContent", "uid")).to eq("99999")
    expect(EventContent.find_by(uid: "99999")).to be_present
  end

  it "returns an error when raw_data is an array" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "99999", rawDataFirst: [1, 2, 3] },
    })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("must be a JSON object")
  end

  it "returns an error when uid is duplicated" do
    FactoryBot.create(:event_content, uid: "99999")
    result = execute_graphql_as_admin(mutation, variables: { input: { uid: "99999" } })
    data = result.dig("data", "createEventContent")
    expect(data["errors"]).to be_present
    expect(data["eventContent"]).to be_nil
  end
end
