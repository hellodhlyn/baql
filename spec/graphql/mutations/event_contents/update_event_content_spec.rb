require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::EventContents::UpdateEventContent, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateEventContentInput!) {
        updateEventContent(input: $input) {
          eventContent { uid }
          errors
        }
      }
    GRAPHQL
  end

  let!(:event_content) { FactoryBot.create(:event_content, uid: "99999") }

  it "updates an EventContent" do
    raw_data = { "stage" => {} }
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "99999", rawDataFirst: raw_data },
    })
    data = result.dig("data", "updateEventContent")
    expect(data["errors"]).to be_empty
    expect(event_content.reload.raw_data_first).to eq(raw_data)
  end

  it "returns an error when uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: { input: { uid: "nonexistent" } })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end
end
