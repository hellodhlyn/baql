# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MainStoryPartSchedules::UpsertMainStoryPartSchedule, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpsertMainStoryPartScheduleInput!) {
        upsertMainStoryPartSchedule(input: $input) {
          mainStoryPartSchedule {
            region
            releasedAt
            confirmed
          }
          errors
        }
      }
    GRAPHQL
  end

  let!(:part) { FactoryBot.create(:main_story_part, uid: "1-1-1") }

  it "creates a schedule when none exists yet" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        partUid: part.uid,
        region: "jp",
        releasedAt: "2026-04-20T12:00:00Z",
        confirmed: true,
      },
    })
    data = result.dig("data", "upsertMainStoryPartSchedule")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryPartSchedule", "region")).to eq("jp")
    expect(data.dig("mainStoryPartSchedule", "confirmed")).to eq(true)

    schedule = MainStoryPartSchedule.find_by(part_uid: part.uid, region: "jp")
    expect(schedule.released_at).to eq(Time.zone.parse("2026-04-20T12:00:00Z"))
    expect(schedule.confirmed).to eq(true)
  end

  it "creates an unconfirmed schedule by default when confirmed is omitted" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { partUid: part.uid, region: "gl", releasedAt: "2026-05-01T00:00:00Z" },
    })
    data = result.dig("data", "upsertMainStoryPartSchedule")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryPartSchedule", "confirmed")).to eq(false)
  end

  it "updates the existing row for the same part_uid and region instead of duplicating it" do
    existing = FactoryBot.create(
      :main_story_part_schedule,
      part_uid: part.uid,
      region: "jp",
      released_at: Time.zone.parse("2026-04-20 12:00:00"),
      confirmed: false,
    )

    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        partUid: part.uid,
        region: "jp",
        releasedAt: "2026-04-25T12:00:00Z",
        confirmed: true,
      },
    })
    data = result.dig("data", "upsertMainStoryPartSchedule")

    expect(data["errors"]).to be_empty
    expect(MainStoryPartSchedule.where(part_uid: part.uid, region: "jp").count).to eq(1)
    expect(existing.reload.released_at).to eq(Time.zone.parse("2026-04-25T12:00:00Z"))
    expect(existing.confirmed).to eq(true)
  end

  it "preserves the existing confirmed value when omitted on update" do
    existing = FactoryBot.create(
      :main_story_part_schedule,
      part_uid: part.uid,
      region: "jp",
      released_at: Time.zone.parse("2026-04-20 12:00:00"),
      confirmed: true,
    )

    result = execute_graphql_as_admin(mutation, variables: {
      input: { partUid: part.uid, region: "jp", releasedAt: "2026-04-26T12:00:00Z" },
    })
    data = result.dig("data", "upsertMainStoryPartSchedule")

    expect(data["errors"]).to be_empty
    expect(existing.reload.confirmed).to eq(true)
  end

  it "returns validation errors when part_uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { partUid: "unknown", region: "jp", releasedAt: "2026-04-20T12:00:00Z" },
    })
    data = result.dig("data", "upsertMainStoryPartSchedule")

    expect(data["errors"]).to be_present
    expect(data["mainStoryPartSchedule"]).to be_nil
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: { partUid: part.uid, region: "jp", releasedAt: "2026-04-20T12:00:00Z" },
    })

    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
