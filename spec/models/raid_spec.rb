require "rails_helper"

RSpec.describe Raid, type: :model do
  describe "#ranks" do
    let(:raid) { FactoryBot.create(:raid, type: "total_assault", raid_index: 70, rank_visible: true) }
    let(:args) { {} }

    before do
      allow(Statics::Raids::Rank).to receive(:parties)
        .with(raid.raid_index)
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

    context "when count is given" do
      let(:args) { { count: 10 } }

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
          { student_id: "13009", tier: 8 },
          { student_id: "10089", tier: 8 },
          { student_id: "20038", tier: 8 },
          { student_id: "20020", tier: 8 },
          { student_id: "10008", tier: 8 },
          { student_id: "10085", tier: 8 },
          # { student_id: "10067", tier: 8 },
          { student_id: "10086", tier: 8 },
          { student_id: "20008", tier: 8 },
          { student_id: "20039", tier: 8 }
        ] }
      end

      it "returns an array of ranks with the given filter" do
        expect(subject).to be_an(Array)
        expect(subject.size).to eq(6)
        expect(subject.map { |row| row[:rank] }).to eq([4, 14, 15, 16, 19, 20])
      end
    end

    context "when rank_visible is false" do
      before { raid.update!(rank_visible: false)   }

      it "returns an empty array" do
        expect(subject).to be_empty
      end
    end
  end
end
