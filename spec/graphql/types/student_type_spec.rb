require "rails_helper"

RSpec.describe Types::StudentType, type: :graphql do
  let(:student) { FactoryBot.create(:student) }
  let(:raid1) { FactoryBot.create(:raid, uid: SecureRandom.uuid, since: 2.weeks.ago) }
  let(:raid2) { FactoryBot.create(:raid, uid: SecureRandom.uuid, since: 4.weeks.ago) }

  describe "#raid_statistics" do
    query = <<~GRAPHQL
      query($studentId: String!, $raidSince: ISO8601DateTime) {
        student(studentId: $studentId) {
          raidStatistics(raidSince: $raidSince) {
            raid { raidId }
          }
        }
      }
    GRAPHQL

    subject { execute_graphql(query, variables: { studentId: student.student_id }) }

    before do
      FactoryBot.create(:raid_statistics, student_id: student.student_id, raid: raid1)
      FactoryBot.create(:raid_statistics, student_id: student.student_id, raid: raid2)
    end

    context "when no argument is provided" do
      it "returns the statistics sorted by since" do
        expect(subject["data"]["student"]["raidStatistics"].count).to eq(2)
        expect(subject["data"]["student"]["raidStatistics"].map { |stat| stat["raid"]["raidId"] }).to eq([raid2.uid, raid1.uid])
      end
    end

    context "when the raid_since argument is provided" do
      subject { execute_graphql(query, variables: { studentId: student.student_id, raidSince: 3.weeks.ago.iso8601 }) }

      it "returns the statistics sorted by since" do
        expect(subject["data"]["student"]["raidStatistics"].count).to eq(1)
        expect(subject["data"]["student"]["raidStatistics"].map { |stat| stat["raid"]["raidId"] }).to eq([raid1.uid])
      end
    end
  end
end
