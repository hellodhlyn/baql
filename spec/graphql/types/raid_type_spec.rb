require "rails_helper"

RSpec.describe Types::RaidType, type: :graphql do
  let(:raid) { FactoryBot.create(:raid, uid: SecureRandom.uuid) }

  describe "#statistics" do
    query = <<~GRAPHQL
      query($uid: String!, $defenseType: Defense!) {
        raid(uid: $uid) {
          statistics(defenseType: $defenseType) {
            defenseType
            slotsCount
          }
        }
      }
    GRAPHQL

    subject { execute_graphql(query, variables: { uid: raid.uid, defenseType: "light" }) }

    context "when multiple defense types exist" do
      before do
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "light", slots_count: 100)
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "heavy", slots_count: 300)
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "elastic", slots_count: 200)
      end

      it "returns statistics for the given defense type" do
        expect(subject["data"]["raid"]["statistics"].count).to eq(1)
        expect(subject["data"]["raid"]["statistics"].first["defenseType"]).to eq("light")
      end
    end

    context "when multiple students exist" do
      before do
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "light", slots_count: 100)
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "light", slots_count: 300)
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "light", slots_count: 200)
      end

      it "sorted by slots_count" do
        expect(subject["data"]["raid"]["statistics"].first["slotsCount"]).to eq(300)
        expect(subject["data"]["raid"]["statistics"].last["slotsCount"]).to eq(100)
      end
    end
  end
end
