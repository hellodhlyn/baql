require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::ScheduleShifts::ShiftContentSchedules, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: ShiftContentSchedulesInput!) {
        shiftContentSchedules(input: $input) {
          dryRun
          totalRows
          scheduleUpdates {
            scheduleType
            identifier
            changes { column before after }
          }
          studentReleaseUpdates {
            uid
            recruitmentGroupUid
            beforeReleaseAt
            afterReleaseAt
            beforeArchiveAt
            afterArchiveAt
          }
          errors
        }
      }
    GRAPHQL
  end

  let(:cutoff) { Time.zone.parse("2026-08-01 00:00:00") }
  let!(:event_schedule) do
    FactoryBot.create(
      :event_content_schedule,
      region: "gl",
      start_at: cutoff,
      end_at: cutoff + 14.days,
    )
  end
  let!(:mini_story_schedule) do
    FactoryBot.create(
      :mini_story_schedule,
      region: "gl",
      released_at: cutoff + 1.day,
    )
  end

  it "previews advancing all target schedules without persisting changes" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        cutoff: cutoff.iso8601,
        days: 7,
        direction: "advance",
      },
    })
    data = result.dig("data", "shiftContentSchedules")

    expect(result["errors"]).to be_nil
    expect(data["errors"]).to be_empty
    expect(data["dryRun"]).to be(true)
    expect(data["totalRows"]).to eq(2)
    expect(data["scheduleUpdates"].pluck("scheduleType")).to contain_exactly(
      "event_content_schedules",
      "mini_story_schedules",
    )
    expect(event_schedule.reload.start_at).to eq(cutoff)
    expect(mini_story_schedule.reload.released_at).to eq(cutoff + 1.day)
  end

  it "applies the shift in one transaction" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        cutoff: cutoff.iso8601,
        days: 7,
        direction: "advance",
        dryRun: false,
      },
    })
    data = result.dig("data", "shiftContentSchedules")

    expect(result["errors"]).to be_nil
    expect(data["errors"]).to be_empty
    expect(data["dryRun"]).to be(false)
    expect(event_schedule.reload.start_at).to eq(cutoff - 7.days)
    expect(event_schedule.end_at).to eq(cutoff + 7.days)
    expect(mini_story_schedule.reload.released_at).to eq(cutoff - 6.days)
  end

  it "rejects non-positive days" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        cutoff: cutoff.iso8601,
        days: 0,
        direction: "advance",
      },
    })

    expect(result["errors"].first["message"]).to eq("days must be a positive integer")
    expect(event_schedule.reload.start_at).to eq(cutoff)
  end
end
