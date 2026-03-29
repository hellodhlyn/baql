require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::Recruitments::CreateRecruitment, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateRecruitmentInput!) {
        createRecruitment(input: $input) {
          recruitment { uid studentName recruitmentType pickup }
          errors
        }
      }
    GRAPHQL
  end

  let!(:group) { FactoryBot.create(:recruitment_group, uid: "20260401") }

  it "creates a Recruitment" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "r-001",
        recruitmentGroupUid: "20260401",
        studentName: "카요코",
        recruitmentType: "limited",
        pickup: true,
      },
    })
    data = result.dig("data", "createRecruitment")
    expect(data["errors"]).to be_empty
    expect(data.dig("recruitment", "uid")).to eq("r-001")
    expect(Recruitment.find_by(uid: "r-001")).to be_present
  end

  it "returns an error when recruitment_group_uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "r-001",
        recruitmentGroupUid: "nonexistent",
        studentName: "카요코",
        recruitmentType: "limited",
      },
    })
    data = result.dig("data", "createRecruitment")
    expect(data["errors"]).to be_present
    expect(data["recruitment"]).to be_nil
  end
end
