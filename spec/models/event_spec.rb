require "rails_helper"

RSpec.describe Event, type: :model do
  describe "#pickups" do
    let(:event) do
      pickups = [
        {"type":"usual","rerun":false,"studentId":"10089"},
        {"type":"usual","rerun":false,"studentName":"카요코(드레스)"},
      ]
      FactoryBot.create(:event, pickups: pickups)
    end

    before do
      FactoryBot.create(:student, student_id: "10089", name: "아루(드레스)")
    end

    subject { event.pickups }

    it "returns an array of pickups" do
      expect(subject).to all(be_a(Event::Pickup))
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

    context "if event_index presents" do
      let(:event) { FactoryBot.create(:event, event_index: 834) }

      it "should return an array of stages" do
        expect(subject).to all(be_a(Event::Stage))
        expect(subject.size).to eq(16)
        expect(subject.first).to have_attributes(
          name: "1F 중앙 테라스",
          difficulty: 1,
          index: "1",
        )

        expect(subject.first.rewards).to all(be_a(Event::StageReward))
        expect(subject.first.rewards.first.item).to be_a(Item)
          .and have_attributes(
            item_id: "80390",
            name: "타깃 단서",
            image_id: "item_icon_event_token_0_s36",
          )
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
