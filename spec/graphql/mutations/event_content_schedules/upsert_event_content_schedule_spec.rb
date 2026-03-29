require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::EventContentSchedules::UpsertEventContentSchedule, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpsertEventContentScheduleInput!) {
        upsertEventContentSchedule(input: $input) {
          eventContentSchedule { region runType startAt }
          errors
        }
      }
    GRAPHQL
  end

  let!(:event_content) { FactoryBot.create(:event_content, uid: "99999") }

  it "creates a new EventContentSchedule" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        eventContentUid: "99999",
        region: "jp",
        runType: "first",
        startAt: "2026-01-01T00:00:00Z",
        endAt: "2026-01-15T00:00:00Z",
      },
    })
    data = result.dig("data", "upsertEventContentSchedule")
    expect(data["errors"]).to be_empty
    expect(data.dig("eventContentSchedule", "region")).to eq("jp")
    expect(EventContentSchedule.find_by(event_content_uid: "99999", region: "jp", run_type: "first")).to be_present
  end

  it "upserts an existing record" do
    FactoryBot.create(:event_content_schedule, event_content: event_content, region: "jp", run_type: "first",
      start_at: "2025-01-01", end_at: "2025-01-15")
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        eventContentUid: "99999",
        region: "jp",
        runType: "first",
        startAt: "2026-02-01T00:00:00Z",
      },
    })
    data = result.dig("data", "upsertEventContentSchedule")
    expect(data["errors"]).to be_empty
    expect(EventContentSchedule.where(event_content_uid: "99999", region: "jp", run_type: "first").count).to eq(1)
  end
end
