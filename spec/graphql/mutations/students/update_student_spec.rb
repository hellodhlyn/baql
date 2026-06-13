require "rails_helper"

# frozen_string_literal: true

RSpec.describe Mutations::Students::UpdateStudent, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateStudentInput!) {
        updateStudent(input: $input) {
          student {
            uid
            altNames
            familyName
            personalName
          }
          errors
        }
      }
    GRAPHQL
  end

  let!(:student) do
    FactoryBot.create(
      :student,
      uid: "10142",
      alt_names: [],
      family_name: nil,
      personal_name: nil,
    )
  end

  it "updates name-related student fields" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: student.uid,
        altNames: ["수구사", "수나구사"],
        familyName: "고료",
        personalName: "나구사",
      },
    })

    data = result.dig("data", "updateStudent")
    expect(data["errors"]).to be_empty
    expect(data["student"]).to eq(
      "uid" => student.uid,
      "altNames" => ["수구사", "수나구사"],
      "familyName" => "고료",
      "personalName" => "나구사",
    )
    expect(student.reload).to have_attributes(
      alt_names:     ["수구사", "수나구사"],
      family_name:   "고료",
      personal_name: "나구사",
    )
  end

  it "returns an error when uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "nonexistent", altNames: ["별칭"] },
    })

    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("not found")
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: { uid: student.uid, altNames: ["별칭"] },
    })

    expect(result["errors"]).to be_present
    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
