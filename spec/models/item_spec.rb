RSpec.describe Item, type: :model do
  describe ".find_by_item_id" do
    let(:item_id) { "80070" }
    let(:rerun_event) { false }

    before do
      stub_request(:get, "https://schaledb.com/data/kr/items.min.json")
        .to_return(body: File.read("spec/_fixtures/items.min.json"))
    end

    subject { Item.find_by_item_id(item_id, rerun_event: rerun_event) }

    shared_examples "returns an item" do
      it do
        expect(subject).to have_attributes(item_id: item_id, name: "특제 신년 복주머니", image_id: "item_icon_event_token_0_s11")
      end
    end

    context "when the item exists" do
      it_behaves_like "returns an item"

      it "returns event bonused for the first run event" do
        expect(subject.event_bonuses.size).to eq(5)
      end
    end

    context "when the item exists and the event is rerun" do
      let(:rerun_event) { true }

      it_behaves_like "returns an item"

      it "returns event bonused for the rerun event" do
        expect(subject.event_bonuses.size).to eq(7)
      end
    end
  end
end
