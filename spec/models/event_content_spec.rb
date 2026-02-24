require "rails_helper"

RSpec.describe EventContent, type: :model do
  # ──────────────────────────────────────────────────────────────
  # #shop_resources
  # ──────────────────────────────────────────────────────────────
  describe "#shop_resources" do
    let(:shop_item_item) do
      {
        "CategoryType" => 13,
        "Id"           => 8500000,
        "IsLegacy"     => false,
        "PurchaseCountLimit" => 90,
        "GoodsId" => [44500],
        "Goods" => [
          {
            "ParcelId"              => [10],
            "ParcelAmount"          => [3],
            "ParcelTypeStr"         => ["Item"],
            "ConsumeParcelId"       => [80681],
            "ConsumeParcelAmount"   => [1],
            "ConsumeParcelTypeStr"  => ["Item"],
          }
        ]
      }
    end

    let(:shop_item_equipment) do
      {
        "CategoryType" => 14,
        "Id"           => 8500100,
        "IsLegacy"     => false,
        "PurchaseCountLimit" => 0,
        "GoodsId" => [44600],
        "Goods" => [
          {
            "ParcelId"              => [1],
            "ParcelAmount"          => [1],
            "ParcelTypeStr"         => ["Equipment"],
            "ConsumeParcelId"       => [80682],
            "ConsumeParcelAmount"   => [5],
            "ConsumeParcelTypeStr"  => ["Item"],
          }
        ]
      }
    end

    let(:shop_item_furniture) do
      {
        "CategoryType" => 13,
        "Id"           => 8500200,
        "IsLegacy"     => false,
        "PurchaseCountLimit" => 1,
        "GoodsId" => [44700],
        "Goods" => [
          {
            "ParcelId"              => [210381],
            "ParcelAmount"          => [1],
            "ParcelTypeStr"         => ["Furniture"],
            "ConsumeParcelId"       => [80681],
            "ConsumeParcelAmount"   => [80],
            "ConsumeParcelTypeStr"  => ["Item"],
          }
        ]
      }
    end

    let(:raw_data) do
      {
        "shop" => {
          "13" => [shop_item_item, shop_item_furniture],
          "14" => [shop_item_equipment],
        }
      }
    end

    subject(:event_content) { EventContent.new(uid: "850", baql_id: "baql::events::850", raw_data_first: raw_data) }

    context "when raw_data_first is nil" do
      subject { EventContent.new(uid: "850", baql_id: "baql::events::850") }

      it "returns an empty array" do
        expect(subject.shop_resources).to eq([])
      end
    end

    context "when the shop key is absent" do
      subject { EventContent.new(uid: "850", baql_id: "baql::events::850", raw_data_first: {}) }

      it "returns an empty array" do
        expect(subject.shop_resources).to eq([])
      end
    end

    context "when run_type is the default (first)" do
      it "parses raw_data_first" do
        expect(event_content.shop_resources.count).to eq(3)
      end
    end

    context "when run_type is 'rerun'" do
      let(:rerun_raw) { { "shop" => { "13" => [shop_item_item] } } }
      subject { EventContent.new(uid: "850", baql_id: "baql::events::850", raw_data_first: raw_data, raw_data_rerun: rerun_raw) }

      it "parses raw_data_rerun" do
        expect(subject.shop_resources(run_type: "rerun").count).to eq(1)
      end
    end

    describe "field mapping" do
      it "normalizes all fields correctly" do
        item = event_content.shop_resources.find { |r| r["uid"] == "8500000" }

        expect(item["uid"]).to eq("8500000")
        expect(item["resource_type"]).to eq("item")
        expect(item["resource_uid"]).to eq("10")
        expect(item["resource_amount"]).to eq(3)
        expect(item["payment_resource_type"]).to eq("item")
        expect(item["payment_resource_uid"]).to eq("80681")
        expect(item["payment_resource_amount"]).to eq(1)
      end
    end

    describe "shop_amount" do
      it "returns the limit when PurchaseCountLimit > 0" do
        item = event_content.shop_resources.find { |r| r["uid"] == "8500000" }
        expect(item["shop_amount"]).to eq(90)
      end

      it "returns nil when PurchaseCountLimit is 0 (unlimited)" do
        item = event_content.shop_resources.find { |r| r["uid"] == "8500100" }
        expect(item["shop_amount"]).to be_nil
      end
    end

    describe "resource_type variety" do
      it "parses Equipment type correctly" do
        item = event_content.shop_resources.find { |r| r["uid"] == "8500100" }
        expect(item["resource_type"]).to eq("equipment")
        expect(item["resource_uid"]).to eq("1")
      end

      it "parses Furniture type correctly" do
        item = event_content.shop_resources.find { |r| r["uid"] == "8500200" }
        expect(item["resource_type"]).to eq("furniture")
        expect(item["resource_uid"]).to eq("210381")
      end
    end

    it "flattens items from all categories into a single array" do
      uids = event_content.shop_resources.map { |r| r["uid"] }
      expect(uids).to contain_exactly("8500000", "8500100", "8500200")
    end

    context "when an item has no Goods" do
      let(:raw_data) do
        {
          "shop" => {
            "13" => [
              shop_item_item,
              { "Id" => 9999999, "PurchaseCountLimit" => 1, "Goods" => [] }
            ]
          }
        }
      end

      it "skips the item with no Goods" do
        expect(event_content.shop_resources.map { |r| r["uid"] }).to contain_exactly("8500000")
      end
    end
  end


  LOCALIZATION_STUBS = {
    "jp" => { "EventName" => { "701" => "特殊作戦・デカグラマトン編", "801" => "桜花爛漫お祭り騒ぎ！" } }.to_json,
    "kr" => { "EventName" => { "701" => "특수 작전 데카그라마톤 편", "801" => "벚꽃만발 축제대소동!" } }.to_json,
    "en" => { "EventName" => { "701" => "Special Mission Decagrammaton", "801" => "Cherry Blossom Festival Commotion!" } }.to_json
  }.freeze

  describe ".sync!" do
    before do
      stub_request(:get, "https://schaledb.com/data/kr/events.min.json")
        .to_return(body: ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/events.json.gz")))

      LOCALIZATION_STUBS.each do |lang_path, body|
        stub_request(:get, "https://schaledb.com/data/#{lang_path}/localization.min.json")
          .to_return(body: body)
      end
    end

    subject { EventContent.sync! }

    it "returns nil" do
      expect(subject).to be_nil
    end

    it "creates EventContent records" do
      expect { subject }.to change { EventContent.count }.by(56)
    end

    it "sets the correct uid and baql_id" do
      subject

      event_701 = EventContent.find_by(uid: "701")
      expect(event_701).to be_present
      expect(event_701.baql_id).to eq("baql::events::701")
    end

    describe "schedule creation" do
      before { subject }

      context "event 701 (Original + Permanent, no Rerun)" do
        let(:event_content) { EventContent.find_by(uid: "701") }

        it "creates schedules only for existing run types" do
          expect(event_content.schedules.pluck(:run_type).uniq).to contain_exactly("first", "permanent")
        end

        it "creates 3 region schedules per run type" do
          expect(event_content.schedules.where(run_type: "first").count).to eq(3)
          expect(event_content.schedules.where(run_type: "permanent").count).to eq(3)
        end

        it "maps timestamps to correct start_at and end_at for Original/jp" do
          schedule = event_content.schedules.find_by(region: "jp", run_type: "first")
          expect(schedule.start_at).to eq(Time.zone.at(1701828000))
          expect(schedule.end_at).to eq(Time.zone.at(1703037600))
        end

        it "sets end_at to nil when close timestamp is 4102412400 (무기한)" do
          schedule = event_content.schedules.find_by(region: "cn", run_type: "permanent")
          expect(schedule.end_at).to be_nil
        end

        it "sets end_at for non-permanent schedules normally" do
          schedule = event_content.schedules.find_by(region: "jp", run_type: "permanent")
          expect(schedule.end_at).to eq(Time.zone.at(1729648800))
        end
      end

      context "event 801 (Original + Rerun + Permanent)" do
        let(:event_content) { EventContent.find_by(uid: "801") }

        it "creates schedules for all run types" do
          expect(event_content.schedules.pluck(:run_type).uniq).to contain_exactly("first", "rerun", "permanent")
        end

        it "creates 9 schedules total (3 run types × 3 regions)" do
          expect(event_content.schedules.count).to eq(9)
        end

        it "sets end_at to nil for all Permanent schedules (all 4102412400)" do
          permanent_schedules = event_content.schedules.where(run_type: "permanent")
          expect(permanent_schedules.pluck(:end_at)).to all(be_nil)
        end

        it "maps Rerun timestamps correctly" do
          schedule = event_content.schedules.find_by(region: "gl", run_type: "rerun")
          expect(schedule.start_at).to eq(Time.zone.at(1663639200))
          expect(schedule.end_at).to eq(Time.zone.at(1664244000))
        end
      end
    end

    describe "idempotency" do
      it "does not create duplicate records when called twice" do
        subject
        expect { EventContent.sync! }.not_to change { EventContent.count }
      end

      it "does not create duplicate schedules when called twice" do
        subject
        expect { EventContent.sync! }.not_to change { EventContentSchedule.count }
      end

      it "updates existing schedules on re-sync" do
        subject

        schedule = EventContent.find_by(uid: "701").schedules.find_by(region: "jp", run_type: "first")
        original_start_at = schedule.start_at

        # 데이터가 바뀌었다고 가정하고 재실행해도 레코드가 중복 생성되지 않음
        EventContent.sync!
        schedule.reload

        expect(schedule.start_at).to eq(original_start_at)
      end
    end

    describe "name translation" do
      before { subject }

      it "returns the ko name by default" do
        event = EventContent.find_by(uid: "701")
        expect(event.name).to eq("특수 작전 데카그라마톤 편")
      end

      it "returns the ja name when specified" do
        event = EventContent.find_by(uid: "701")
        expect(event.name("ja")).to eq("特殊作戦・デカグラマトン編")
      end

      it "returns the en name when specified" do
        event = EventContent.find_by(uid: "801")
        expect(event.name("en")).to eq("Cherry Blossom Festival Commotion!")
      end

      it "returns nil for an event without a translation" do
        event = EventContent.find_by(uid: "701")
        expect(event.name("zh")).to be_nil
      end

      describe "idempotency" do
        it "does not create duplicate Translation records when called twice" do
          expect { EventContent.sync! }.not_to change { Translation.count }
        end
      end
    end
  end
end
