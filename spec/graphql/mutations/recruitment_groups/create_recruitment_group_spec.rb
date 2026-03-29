require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::RecruitmentGroups::CreateRecruitmentGroup, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateRecruitmentGroupInput!) {
        createRecruitmentGroup(input: $input) {
          recruitmentGroup { uid recruitmentType }
          errors
        }
      }
    GRAPHQL
  end

  it "creates a RecruitmentGroup" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "20260401",
        recruitmentType: "limited",
        startAt: "2026-04-01T02:00:00Z",
        endAt: "2026-04-15T02:00:00Z",
      },
    })
    data = result.dig("data", "createRecruitmentGroup")
    expect(data["errors"]).to be_empty
    expect(data.dig("recruitmentGroup", "uid")).to eq("20260401")
    expect(RecruitmentGroup.find_by(uid: "20260401")).to be_present
  end

  it "creates with nested recruitments" do
    mutation_with_recruitments = <<~GRAPHQL
      mutation($input: CreateRecruitmentGroupInput!) {
        createRecruitmentGroup(input: $input) {
          recruitmentGroup { uid }
          errors
        }
      }
    GRAPHQL
    result = execute_graphql_as_admin(mutation_with_recruitments, variables: {
      input: {
        uid: "20260401",
        recruitmentType: "limited",
        startAt: "2026-04-01T02:00:00Z",
        recruitments: [
          { uid: "r-001", studentName: "카요코", recruitmentType: "limited", pickup: true },
        ],
      },
    })
    data = result.dig("data", "createRecruitmentGroup")
    expect(data["errors"]).to be_empty
    expect(Recruitment.find_by(uid: "r-001")).to be_present
  end

  it "returns an error when uid is duplicated" do
    FactoryBot.create(:recruitment_group, uid: "20260401")
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "20260401",
        recruitmentType: "limited",
        startAt: "2026-04-01T02:00:00Z",
      },
    })
    data = result.dig("data", "createRecruitmentGroup")
    expect(data["errors"]).to be_present
    expect(data["recruitmentGroup"]).to be_nil
  end
end
