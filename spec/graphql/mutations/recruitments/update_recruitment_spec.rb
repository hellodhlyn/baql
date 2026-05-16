require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::Recruitments::UpdateRecruitment, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateRecruitmentInput!) {
        updateRecruitment(input: $input) {
          recruitment { uid studentName pickup }
          errors
        }
      }
    GRAPHQL
  end

  let!(:recruitment) { FactoryBot.create(:recruitment, uid: "r-001", student_name: "카요코", pickup: true) }

  it "updates a Recruitment" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "r-001", studentName: "치나츠", pickup: false },
    })
    data = result.dig("data", "updateRecruitment")
    expect(data["errors"]).to be_empty
    expect(data.dig("recruitment", "studentName")).to eq("치나츠")
    expect(recruitment.reload.student_name).to eq("치나츠")
    expect(recruitment.reload.pickup).to be false
  end

  it "updates recruitment dates for both the previous and current student" do
    old_student = FactoryBot.create(:student, uid: "old-student", release_at: nil)
    new_student = FactoryBot.create(:student, uid: "new-student", release_at: nil)
    group = recruitment.recruitment_group
    group.update!(start_at: Time.zone.parse("2026-04-01 02:00:00"))
    recruitment.update!(student_uid: old_student.uid, recruitment_type: "limited")

    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: recruitment.uid,
        studentUid: new_student.uid,
        recruitmentType: "archive",
      },
    })

    expect(result.dig("data", "updateRecruitment", "errors")).to be_empty
    expect(old_student.reload.release_at).to be_nil
    expect(old_student.archive_at).to be_nil
    expect(new_student.reload.release_at).to eq(group.start_at)
    expect(new_student.archive_at).to eq(group.start_at)
  end

  it "returns an error when uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "nonexistent", studentName: "치나츠" },
    })
    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end
end
