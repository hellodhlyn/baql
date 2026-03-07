require "rails_helper"

RSpec.describe Queries::RecruitmentGroupQuery, type: :graphql do
  def query(content_uid)
    <<~GRAPHQL
      query {
        recruitmentGroup(contentUid: "#{content_uid}") {
          uid
          startAt
          endAt
          contentType
          contentUid
          recruitments {
            uid
            recruitmentType
            pickup
            studentName
          }
        }
      }
    GRAPHQL
  end

  describe "find by content_uid" do
    let!(:group) do
      FactoryBot.create(:recruitment_group,
        uid: "some-event",
        content_type: "event_content",
        content_uid: "834")
    end

    before do
      FactoryBot.create(:recruitment, recruitment_group_uid: group.uid, student_name: "카요코", recruitment_type: "limited", pickup: true)
    end

    it "returns the matching group" do
      result = execute_graphql(query("834"))
      data = result["data"]["recruitmentGroup"]
      expect(data["uid"]).to eq("some-event")
      expect(data["contentType"]).to eq("event_content")
      expect(data["contentUid"]).to eq("834")
    end

    it "returns recruitments" do
      result = execute_graphql(query("834"))
      recruitments = result["data"]["recruitmentGroup"]["recruitments"]
      expect(recruitments).to contain_exactly(
        a_hash_including("studentName" => "카요코", "recruitmentType" => "limited", "pickup" => true)
      )
    end
  end

  describe "when no group exists for content_uid" do
    it "returns null" do
      result = execute_graphql(query("9999"))
      expect(result["data"]["recruitmentGroup"]).to be_nil
    end
  end

  describe "studentName resolution" do
    let(:group) { FactoryBot.create(:recruitment_group, content_type: "event_content", content_uid: "835") }

    context "when student is linked" do
      before do
        FactoryBot.create(:student, uid: "13005", name: "카요코(최신)")
        FactoryBot.create(:recruitment, recruitment_group_uid: group.uid, student_uid: "13005", student_name: "카요코(구버전)")
      end

      it "returns the student's current name" do
        result = execute_graphql(query("835"))
        student_name = result["data"]["recruitmentGroup"]["recruitments"].first["studentName"]
        expect(student_name).to eq("카요코(최신)")
      end
    end

    context "when student is not linked" do
      before do
        FactoryBot.create(:recruitment, recruitment_group_uid: group.uid, student_uid: nil, student_name: "미공개학생")
      end

      it "returns student_name" do
        result = execute_graphql(query("835"))
        student_name = result["data"]["recruitmentGroup"]["recruitments"].first["studentName"]
        expect(student_name).to eq("미공개학생")
      end
    end
  end
end
