require "rails_helper"

RSpec.describe RaidStatistics, type: :model do
  describe ".sync!" do
    let!(:student1) { FactoryBot.create(:student, student_id: "13005", release_at: 1.month.ago) }
    let!(:student2) { FactoryBot.create(:student, student_id: "13006", release_at: 2.months.ago) }
    let!(:unreleased_student) { FactoryBot.create(:student, student_id: "13007", release_at: nil) }

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
            parties: [
              [
                { student_id: "13005", tier: rank <= 30 ? 8 : 3 },
                { student_id: "13006", tier: 5, is_assist: rank % 2 == 0 },
                { student_id: "13007", tier: rank <= 20 ? 7 : 4, is_assist: true }
              ]
            ],
          }
        end
      )
    end

    subject { RaidStatistics.sync!(raid_uid: raid.uid) }

    context "when the raid is visible" do
      it "creates expected records" do
        expect { subject }.to change { RaidStatistics.count }.by(9)
        expect(RaidStatistics.find_by(student_id: "13005", defense_type: "elastic")).to have_attributes(
          slots_count: 39,
          slots_by_tier: { "3" => 9, "8" => 30 },
          assists_count: 0,
          assists_by_tier: {},
        )
        expect(RaidStatistics.find_by(student_id: "13006", defense_type: "elastic")).to have_attributes(
          slots_count: 20,
          slots_by_tier: { "5" => 20 },
          assists_count: 19,
          assists_by_tier: { "5" => 19 },
        )
        expect(RaidStatistics.find_by(student_id: "13007", defense_type: "elastic")).to have_attributes(
          slots_count: 0,
          slots_by_tier: {},
          assists_count: 39,
          assists_by_tier: { "4" => 19, "7" => 20 },
        )
      end
    end

    context "when the raid is not visible" do
      before do
        raid.update(rank_visible: false)
      end

      it "does not create any records" do
        expect { subject }.not_to change { RaidStatistics.count }
      end
    end
  end
end
