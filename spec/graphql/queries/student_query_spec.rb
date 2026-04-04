require "rails_helper"

RSpec.describe Queries::StudentQuery, type: :graphql do
  subject { Queries::StudentQuery.new(object: nil, context: query_context, field: nil) }

  let(:student_skills) do
    {
      "Skills" => {
        "Ex" => { "Name" => "패닉 브링거" },
        "Public" => { "Name" => "패닉샷" },
        "Passive" => { "Name" => "무서운 얼굴" },
        "ExtraPassive" => { "Name" => "어쩔 수 없네" },
      },
    }
  end

  describe "#resolve" do
    before do
      FactoryBot.create(:student, name: "호시노(무장)", uid: "10098", multiclass_uid: "10098")
      FactoryBot.create(:student, name: "호시노(무장)", uid: "10099", multiclass_uid: "10098")
    end

    it "returns a student" do
      results = subject.resolve(uid: "10098")
      expect(results.uid).to eq("10098")
    end
  end

  describe "student skills field" do
    let!(:student) { FactoryBot.create(:student, uid: "13005", raw_data: student_skills) }

    it "returns skill names extracted from raw_data" do
      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            skills {
              skillType
              name
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "skills")).to eq([
        { "skillType" => "ex", "name" => "패닉 브링거" },
        { "skillType" => "public", "name" => "패닉샷" },
        { "skillType" => "passive", "name" => "무서운 얼굴" },
        { "skillType" => "extra_passive", "name" => "어쩔 수 없네" },
      ])
    end

    it "filters skills by skill_type" do
      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            skills(skillType: ex) {
              skillType
              name
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "skills")).to eq([
        { "skillType" => "ex", "name" => "패닉 브링거" },
      ])
    end

    it "returns an empty array when no skills are present" do
      student.update!(raw_data: {})

      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            skills {
              skillType
              name
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "skills")).to eq([])
    end
  end
end
