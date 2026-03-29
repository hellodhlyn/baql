require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::JointFiringDrillSchedules::UpsertJointFiringDrillSchedule, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpsertJointFiringDrillScheduleInput!) {
        upsertJointFiringDrillSchedule(input: $input) {
          jointFiringDrillSchedule { region startAt }
          errors
        }
      }
    GRAPHQL
  end

  let!(:drill) { FactoryBot.create(:joint_firing_drill, uid: "jfd-1", season: 1) }

  it "creates a new JointFiringDrillSchedule" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        drillUid: "jfd-1",
        region: "jp",
        startAt: "2026-04-01T00:00:00Z",
        endAt: "2026-04-15T00:00:00Z",
      },
    })
    data = result.dig("data", "upsertJointFiringDrillSchedule")
    expect(data["errors"]).to be_empty
    expect(data.dig("jointFiringDrillSchedule", "region")).to eq("jp")
    expect(JointFiringDrillSchedule.find_by(drill_uid: "jfd-1", region: "jp")).to be_present
  end

  it "upserts an existing record" do
    FactoryBot.create(:joint_firing_drill_schedule, drill: drill, region: "jp",
      start_at: "2025-01-01", end_at: "2025-01-15")
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        drillUid: "jfd-1",
        region: "jp",
        startAt: "2026-02-01T00:00:00Z",
      },
    })
    data = result.dig("data", "upsertJointFiringDrillSchedule")
    expect(data["errors"]).to be_empty
    expect(JointFiringDrillSchedule.where(drill_uid: "jfd-1", region: "jp").count).to eq(1)
  end
end
