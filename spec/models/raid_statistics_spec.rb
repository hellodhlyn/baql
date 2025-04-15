require 'rails_helper'

RSpec.describe RaidStatistics, type: :model do
  describe '.sync!' do
    let!(:student) { FactoryBot.create(:student, student_id: '13005', release_at: 1.month.ago) }
    let!(:raid) do
      FactoryBot.create(:raid,
        since: 2.weeks.ago,
        rank_visible: true,
        raid_index_jp: 39,
        defense_types: [
          { defense_type: "elastic", difficulty: "insane" },
          { defense_type: "heavy", difficulty: "insane" },
          { defense_type: "special", difficulty: "torment" },
        ],
      )
    end

    before do
      allow_any_instance_of(Raid).to receive(:ranks).and_return(
        (1..39).map do |rank|
          {
            rank: rank,
            score: 10000,
            parties: [[{ student_id: "13005", tier: rank <= 30 ? 8 : 3 }]],
          }
        end
      )
    end

    subject { described_class.sync!(student_id: student.student_id) }

    context "when student has released and participated in the raid" do
      it "creates a new raid statistics record" do
        expect { subject }.to change { RaidStatistics.count }.by(3)
        expect(RaidStatistics.last).to have_attributes(
          student_id:     student.student_id,
          raid:           raid,
          defense_type:   "special",
          difficulty:     "torment",
          counts_by_tier: { 3 => 9, 8 => 30 },
        )
      end
    end

    context "when student has not released" do
      before { student.update!(release_at: nil) }

      it "does not create a new raid statistics record" do
        expect { subject }.not_to change { RaidStatistics.count }
      end
    end

    context "when date of the raid is before the release date" do
      before { raid.update!(since: 3.months.ago) }

      it "does not create a new raid statistics record" do
        expect { subject }.not_to change { RaidStatistics.count }
      end
    end

    context "when statistics already exists" do
      before { FactoryBot.create(:raid_statistics, student_id: student.student_id, raid: raid) }

      it "does not create a new raid statistics record" do
        expect { subject }.not_to change { RaidStatistics.count }
      end
    end
  end
end
