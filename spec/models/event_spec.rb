require "rails_helper"

RSpec.describe Event, type: :model do
  describe "#pickups" do
    let(:event) { FactoryBot.create(:event) }

    before do
      FactoryBot.create(:student, uid: "10089", name: "아루(드레스)")
      
      FactoryBot.create(:pickup, event: event, student_uid: "10089")
      FactoryBot.create(:pickup, event: event, fallback_student_name: "카요코(드레스)")
    end

    subject { event.pickups }

    it "returns an array of pickups" do
      expect(subject).to all(be_a(Pickup))
    end

    it "returns names of students" do
      expect(subject.map(&:student_name)).to eq(["아루(드레스)", "카요코(드레스)"])
    end
  end

  describe "#stages" do
    before do
      stub_request(:get, "https://schaledb.com/data/kr/events.min.json")
        .to_return(body: File.read("spec/_fixtures/events.min.json"))

      stub_request(:get, "https://schaledb.com/data/kr/items.min.json")
        .to_return(body: File.read("spec/_fixtures/items.min.json"))
    end

    subject { event.stages }

    context "if event_index presents and the event is not rerun" do
      let(:event) { FactoryBot.create(:event, event_index: 809) }

      it "should return an array of stages" do
        expect(subject).to all(be_a(Event::Stage))
        expect(subject.size).to eq(17)
        expect(subject.first).to have_attributes(
          name: "해돋이산 남쪽 길",
          difficulty: 1,
          index: "1",
        )
      end

      it "returns an array of rewards" do
        expect(subject.first.rewards).to all(be_a(Event::StageReward))
        expect(subject.first.rewards.size).to eq(3)
        expect(subject.first.rewards.first.item[:item_id]).to eq("80070")
        expect(subject.first.rewards.first.item[:name]).to eq("특제 신년 복주머니")
        expect(subject.first.rewards.first.item[:image_id]).to eq("item_icon_event_token_0_s11")
        expect(subject.first.rewards.first.item[:event_bonuses].size).to eq(5)
      end
    end

    context "if event_index presents and the event is rerun" do
      let(:event) { FactoryBot.create(:event, event_index: 809, rerun: true) }

      it "returns an array of rewards" do
        expect(subject.first.rewards.first.item[:event_bonuses].size).to eq(7)
      end
    end

    context "if event_index does not present" do
      let(:event) { FactoryBot.create(:event) }

      it "should return an empty array" do
        expect(subject).to eq([])
      end
    end
  end
end
