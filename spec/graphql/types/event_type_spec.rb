require "rails_helper"

RSpec.describe Types::EventType, type: :graphql do
  let(:event) { FactoryBot.create(:event) }

  describe "#pickups" do
    query = <<~GRAPHQL
      query($uid: String!) {
        event(uid: $uid) {
          pickups {
            studentName
          }
        }
      }
    GRAPHQL

    subject { execute_graphql(query, variables: { uid: event.uid }) }

    before do
      FactoryBot.create(:pickup, id: 3, event: event, student_uid: "10089", fallback_student_name: "아루(드레스)")
      FactoryBot.create(:pickup, id: 2, event: event, student_uid: "10090", fallback_student_name: "카요코(드레스)")
      FactoryBot.create(:pickup, id: 1, event: event, student_uid: "10091", fallback_student_name: "호시노(드레스)")
    end

    it "returns pickups ordered by id" do
      expect(subject["data"]["event"]["pickups"].map { |pickup| pickup["studentName"] }).to eq([
        "호시노(드레스)",
        "카요코(드레스)",
        "아루(드레스)"
      ])
    end
  end
end
