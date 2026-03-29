require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::JointFiringDrills::CreateJointFiringDrill, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateJointFiringDrillInput!) {
        createJointFiringDrill(input: $input) {
          jointFiringDrill { uid season drillType terrain defenseType confirmed }
          errors
        }
      }
    GRAPHQL
  end

  it "creates a JointFiringDrill" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "jfd-1",
        season: 1,
        drillType: "shooting",
        terrain: "outdoor",
        defenseType: "normal",
      },
    })
    data = result.dig("data", "createJointFiringDrill")
    expect(data["errors"]).to be_empty
    expect(data.dig("jointFiringDrill", "uid")).to eq("jfd-1")
    expect(data.dig("jointFiringDrill", "confirmed")).to be true
    expect(JointFiringDrill.find_by(uid: "jfd-1")).to be_present
  end

  it "creates with nested schedules" do
    mutation_with_schedules = <<~GRAPHQL
      mutation($input: CreateJointFiringDrillInput!) {
        createJointFiringDrill(input: $input) {
          jointFiringDrill { uid schedules { region } }
          errors
        }
      }
    GRAPHQL
    result = execute_graphql_as_admin(mutation_with_schedules, variables: {
      input: {
        uid: "jfd-2",
        season: 2,
        drillType: "defense",
        terrain: "indoor",
        defenseType: "light",
        schedules: [
          { region: "jp", startAt: "2026-04-01T00:00:00Z" },
          { region: "gl", startAt: "2026-04-08T00:00:00Z", endAt: "2026-04-22T00:00:00Z" },
        ],
      },
    })
    data = result.dig("data", "createJointFiringDrill")
    expect(data["errors"]).to be_empty
    expect(JointFiringDrillSchedule.where(drill_uid: "jfd-2").count).to eq(2)
  end

  it "returns an error when uid is duplicated" do
    FactoryBot.create(:joint_firing_drill, uid: "jfd-1", season: 1)
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "jfd-1",
        season: 99,
        drillType: "shooting",
        terrain: "outdoor",
        defenseType: "normal",
      },
    })
    data = result.dig("data", "createJointFiringDrill")
    expect(data["errors"]).to be_present
    expect(data["jointFiringDrill"]).to be_nil
  end
end
