require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::RecruitmentGroups::UpdateRecruitmentGroup, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateRecruitmentGroupInput!) {
        updateRecruitmentGroup(input: $input) {
          recruitmentGroup { uid recruitmentType }
          errors
        }
      }
    GRAPHQL
  end

  let!(:group) { FactoryBot.create(:recruitment_group, uid: "20260401", recruitment_type: "limited") }

  it "updates a RecruitmentGroup" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "20260401", recruitmentType: "fes" },
    })
    data = result.dig("data", "updateRecruitmentGroup")
    expect(data["errors"]).to be_empty
    expect(data.dig("recruitmentGroup", "recruitmentType")).to eq("fes")
    expect(group.reload.recruitment_type).to eq("fes")
  end

  it "returns an error when uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "nonexistent", recruitmentType: "fes" },
    })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end
end
