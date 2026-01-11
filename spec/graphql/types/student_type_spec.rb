require "rails_helper"

RSpec.describe Types::StudentType, type: :graphql do
  let(:student) { FactoryBot.create(:student) }
  let(:raid1) { FactoryBot.create(:raid, uid: SecureRandom.uuid, since: 2.weeks.ago) }
  let(:raid2) { FactoryBot.create(:raid, uid: SecureRandom.uuid, since: 4.weeks.ago) }

  describe "#pickups" do
    query = <<~GRAPHQL
      query($studentUid: String!) {
        student(uid: $studentUid) {
          pickups {
            studentName rerun
          }
        }
      }
    GRAPHQL

    subject { execute_graphql(query, variables: { studentUid: student.uid }) }

    let(:student) { FactoryBot.create(:student, uid: "13005", name: "카요코") }
    before do
      FactoryBot.create(:pickup, student: student, since: 2.weeks.ago, rerun: true)
      FactoryBot.create(:pickup, student: student, since: 4.weeks.ago, rerun: false)
    end

    it "returns the pickups sorted by since" do
      expect(subject["data"]["student"]["pickups"].count).to eq(2)
      expect(subject["data"]["student"]["pickups"].map { |pickup| pickup["rerun"] }).to eq([false, true])
    end
  end
end
