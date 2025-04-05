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

    context "when rank_before is given" do
      let(:args) { { rank_before: 11, first: 5 } }

      it "returns an array of ranks before the given rank" do
        expect(subject.size).to eq(5)
        expect(subject.last[:rank]).to eq(10)
      end
    end

    context "when first is given" do
      let(:args) { { first: 10 } }

      it "returns an array of ranks with the given count" do
        expect(subject.size).to eq(10)
        expect(subject.first[:rank]).to eq(1)
      end
    end

    context "when include_students is given" do
      context "case #1" do
        let(:args) do
          { include_students: [
            { student_id: "10008", tier: 3 }, # 네루
          ] }
        end

        it "returns if all include_students are present in the row" do
          expect(subject).to be_an(Array)
          expect(subject.size).to eq(8)
          expect(subject.map { |row| row[:rank] }).to eq([1, 2, 4, 14, 15, 16, 19, 20])
        end
      end

      context "case #3" do
        let(:args) do
          { include_students: [
            { student_id: "10008", tier: 3 }, # 네루
            { student_id: "20038", tier: 7 }, # 토모에(치파오)
          ] }
        end

        it "returns if all include_students are present in the row" do
          expect(subject).to be_an(Array)
          expect(subject.size).to eq(5)
          expect(subject.map { |row| row[:rank] }).to eq([1, 2, 16, 19, 20])
        end
      end
    end

    context "when include_students and first is given" do
      let(:args) do
        { include_students: [{ student_id: "10008", tier: 3 }], first: 5 }
      end

      it "returns an array of ranks with the given count" do
        expect(subject.size).to eq(5)
        expect(subject.map { |row| row[:rank] }).to eq([1, 2, 4, 14, 15])
      end
    end

    context "when include_students and rank_after is given" do
        let(:args) do
        { include_students: [{ student_id: "10008", tier: 3 }], rank_after: 4 }
      end

      it "returns an array of ranks after the given rank (exclusive)" do
        expect(subject.size).to eq(5)
        expect(subject.map { |row| row[:rank] }).to eq([14, 15, 16, 19, 20])
      end
    end

    context "when include_students and rank_before is given" do
      let(:args) do
        { include_students: [{ student_id: "10008", tier: 3 }], rank_before: 16 }
      end

      it "returns an array of ranks before the given rank (exclusive)" do
        expect(subject.size).to eq(5)
        expect(subject.map { |row| row[:rank] }).to eq([1, 2, 4, 14, 15])
      end
    end

    context "when include_students and rank_after and first is given" do
      let(:args) do
        { include_students: [{ student_id: "10008", tier: 3 }], rank_after: 4, first: 3 }
      end

      it "returns an array of ranks after the given rank (exclusive)" do
        expect(subject.size).to eq(3)
        expect(subject.map { |row| row[:rank] }).to eq([14, 15, 16])
      end
    end

    context "when include_students and rank_before and first is given" do
      let(:args) do
        { include_students: [{ student_id: "10008", tier: 3 }], rank_before: 16, first: 3 }
      end

      it "returns an array of ranks before the given rank (exclusive)" do
        expect(subject.size).to eq(3)
        expect(subject.map { |row| row[:rank] }).to eq([4, 14, 15])
      end
    end

    context "when exclude_students is given" do
      context "case #1" do
        let(:args) do
          { exclude_students: [
            { student_id: "10008", tier: 3 }, # 네루
          ] }
        end

        it "not returns if any exclude_students are present in the row" do
          expect(subject).to be_an(Array)
          expect(subject.size).to eq(12)
          expect(subject.map { |row| row[:rank] }).to eq([3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 18])
        end
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

      let(:args) { { include_students: [{ student_id: "10000", tier: 8 }] } }

      it "returns an array of ranks with the given include_students" do
        expect(subject.size).to eq(1)
      end
    end
  end
end
