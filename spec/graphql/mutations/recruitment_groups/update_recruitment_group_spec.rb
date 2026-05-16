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

  it "updates recruitment dates for students in the group when start_at changes" do
    student = FactoryBot.create(:student, uid: "student-1", release_at: nil)
    FactoryBot.create(:recruitment, recruitment_group_uid: group.uid, student_uid: student.uid, recruitment_type: "archive")
    next_start_at = Time.zone.parse("2026-05-01 02:00:00")

    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: group.uid, startAt: next_start_at.iso8601 },
    })

    expect(result.dig("data", "updateRecruitmentGroup", "errors")).to be_empty
    expect(student.reload.release_at).to eq(next_start_at)
    expect(student.archive_at).to eq(next_start_at)
  end

  it "returns an error when uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "nonexistent", recruitmentType: "fes" },
    })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end
end
