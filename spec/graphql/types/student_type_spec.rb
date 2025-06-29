require "rails_helper"

RSpec.describe Types::StudentType, type: :graphql do
  let(:student) { FactoryBot.create(:student) }
  let(:raid1) { FactoryBot.create(:raid, uid: SecureRandom.uuid, since: 2.weeks.ago) }
  let(:raid2) { FactoryBot.create(:raid, uid: SecureRandom.uuid, since: 4.weeks.ago) }

  describe "#raid_statistics" do
    query = <<~GRAPHQL
      query($studentUid: String!, $raidSince: ISO8601DateTime) {
        student(uid: $studentUid) {
          raidStatistics(raidSince: $raidSince) {
            raid { uid }
          }
        }
      }
    GRAPHQL

    subject { execute_graphql(query, variables: { studentUid: student.uid }) }

    before do
      FactoryBot.create(:raid_statistics, student_uid: student.uid, raid: raid1)
      FactoryBot.create(:raid_statistics, student_uid: student.uid, raid: raid2)
    end

    context "when no argument is provided" do
      it "returns the statistics sorted by since" do
        expect(subject["data"]["student"]["raidStatistics"].count).to eq(2)
        expect(subject["data"]["student"]["raidStatistics"].map { |stat| stat["raid"]["uid"] }).to eq([raid2.uid, raid1.uid])
      end
    end

    context "when the raid_since argument is provided" do
      subject { execute_graphql(query, variables: { studentUid: student.uid, raidSince: 3.weeks.ago.iso8601 }) }

      it "returns the statistics sorted by since" do
        expect(subject["data"]["student"]["raidStatistics"].count).to eq(1)
        expect(subject["data"]["student"]["raidStatistics"].map { |stat| stat["raid"]["uid"] }).to eq([raid1.uid])
      end
    end
  end

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
