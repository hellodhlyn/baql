require "rails_helper"

RSpec.describe "EventContent raw data schema removal", type: :graphql do
  let!(:event_content) { FactoryBot.create(:event_content, uid: "99999") }

  it "does not expose raw-data fields, including to admins" do
    query = <<~GRAPHQL
      query($uid: String!) {
        eventContent(uid: $uid) {
          uid
          rawDataFirst
          rawDataRerun
        }
      }
    GRAPHQL
    result = execute_graphql_as_admin(query, variables: { uid: event_content.uid })

    expect(result["errors"]).to be_present
    expect(result["errors"].map { |error| error["message"] }.join(" ")).to include("rawDataFirst")
  end
end
