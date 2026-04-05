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

  describe "student gear field" do
    let!(:item_5017) { FactoryBot.create(:item, uid: "5017", name: "안티키테라 장치", rarity: 3) }
    let!(:item_150) { FactoryBot.create(:item, uid: "150", name: "네브라 디스크", rarity: 2) }
    let!(:item_151) { FactoryBot.create(:item, uid: "151", name: "아틀라스 원반", rarity: 4) }

    context "when the student has gear data" do
      let!(:student) do
        FactoryBot.create(
          :student,
          uid: "13005",
          raw_data: {
            "Gear" => {
              "Name" => "아루의 엄청 귀중한 지갑",
              "TierUpMaterial" => [[5017, 150, 151]],
              "TierUpMaterialAmount" => [[4, 80, 25]],
            },
          }
        )
      end

      it "returns the gear name and growth items" do
        result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
          query($uid: String!) {
            student(uid: $uid) {
              gear {
                name
                growthItems {
                  gearTier
                  amount
                  item {
                    uid
                    name
                  }
                }
              }
            }
          }
        GRAPHQL

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "student", "gear")).to eq(
          {
            "name" => "아루의 엄청 귀중한 지갑",
            "growthItems" => [
              {
                "gearTier" => 2,
                "amount" => 4,
                "item" => { "uid" => "5017", "name" => "안티키테라 장치" },
              },
              {
                "gearTier" => 2,
                "amount" => 80,
                "item" => { "uid" => "150", "name" => "네브라 디스크" },
              },
              {
                "gearTier" => 2,
                "amount" => 25,
                "item" => { "uid" => "151", "name" => "아틀라스 원반" },
              },
            ],
          }
        )
      end
    end

    context "when the student does not have gear data" do
      let!(:student) { FactoryBot.create(:student, uid: "13005", raw_data: { "Gear" => {} }) }

      it "returns null" do
        result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
          query($uid: String!) {
            student(uid: $uid) {
              gear {
                name
              }
            }
          }
        GRAPHQL

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "student", "gear")).to be_nil
      end
    end
  end
end
