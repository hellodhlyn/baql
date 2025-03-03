require "rails_helper"

RSpec.describe Raid, type: :model do
  describe "#ranks" do
    let(:raid) { FactoryBot.create(:raid, type: "total_assault", raid_index_jp: 70, rank_visible: true) }
    let(:args) { {} }

    before do
      allow(Statics::Raids::Rank).to receive(:parties)
        .with(raid.raid_index_jp)
        .and_return(JSON.parse(ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/raid_rank.json.gz"))).map(&:deep_symbolize_keys))
    end

    subject { raid.ranks(**args) }

    context "when no args are given" do
      it "returns an array of ranks" do
        expect(subject.size).to eq(20)
      end
    end

    context "when rank_after is given" do
      let(:args) { { rank_after: 10 } }

      it "returns an array of ranks after the given rank" do
        expect(subject.size).to eq(10)
        expect(subject.first[:rank]).to eq(11)
      end
    end

    context "when first is given" do
      let(:args) { { first: 10 } }

      it "returns an array of ranks with the given count" do
        expect(subject.size).to eq(10)
        expect(subject.first[:rank]).to eq(1)
      end
    end

    context "when filter is given" do
      let(:args) do
        { filter: [
          { student_id: "10000", tier: 8 },
          { student_id: "10045", tier: 8 },
          { student_id: "10045", tier: 8 },
          { student_id: "10067", tier: 8 },
          { student_id: "10085", tier: 8 },
          { student_id: "10086", tier: 8 },
          { student_id: "10089", tier: 8 },
          { student_id: "13009", tier: 8 },
          { student_id: "20038", tier: 8 },
          { student_id: "20020", tier: 8 },
          { student_id: "20008", tier: 8 },
          { student_id: "20039", tier: 8 }
        ] }
      end

      it "returns an array of ranks with the given filter" do
        expect(subject).to be_an(Array)
        expect(subject.size).to eq(12)
        expect(subject.map { |row| row[:rank] }).to eq([3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 18])
      end
    end

    context "when rank_visible is false" do
      before { raid.update!(rank_visible: false)   }

      it "returns an empty array" do
        expect(subject).to be_empty
      end
    end

    context "when multiclass students are present" do
      before do
        FactoryBot.create(:student, student_id: "10000", multiclass_id: "10000")
        FactoryBot.create(:student, student_id: "10001", multiclass_id: "10000")

        allow(Statics::Raids::Rank).to receive(:parties)
          .with(raid.raid_index_jp)
          .and_return([{
            rank: 1,
            score: 39,
            parties: [[{ student_id: "10001", tier: 8 }]],
          }])
      end

      let(:args) { { filter: [{ student_id: "10000", tier: 8 }] } }

      it "returns an array of ranks with the given filter" do
        expect(subject.size).to eq(1)
      end
    end

    context "when students in parties are duplicated" do
      before do
        allow(Statics::Raids::Rank).to receive(:parties)
          .with(raid.raid_index_jp)
          .and_return([{
            rank: 1,
            score: 39,
            parties: [
              [{ student_id: "10000", tier: 8 }],
              [{ student_id: "10000", tier: 8 }]
            ]
          }])
      end

      context "when the filter is not enough" do
        let(:args) { { filter: [{ student_id: "10000", tier: 8 }] } }
        it "returns an empty array" do
          expect(subject.size).to eq(0)
        end
      end

      context "when the filter is enough" do
        let(:args) { { filter: [{ student_id: "10000", tier: 8 }, { student_id: "10000", tier: 8 }] } }
        it "returns an array of ranks with the given filter" do
          expect(subject.size).to eq(1)
        end
      end
    end
  end
end
