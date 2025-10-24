RSpec.describe Resources::Item, type: :model do
  describe ".sync!" do
    subject { Resources::Item.sync! }

    before do
      stub_request(:get, "https://schaledb.com/data/kr/items.min.json")
        .to_return(body: File.read("spec/_fixtures/items.min.json"))

      allow(SchaleDB::V1::Images).to receive(:item_icon).and_return(nil)
    end

    it "syncs items from the source URL" do
      expect { subject }.to change { Resources::Item.count }.by(4)
      expect(Resources::Item.find_by(uid: "80070")).to have_attributes(
        name: "특제 신년 복주머니",
        category: "coin",
        rarity: 1,
      )
    end
  end
end
