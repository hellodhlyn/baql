require "rails_helper"

RSpec.describe EventContent, type: :model do
  LOCALIZATION_STUBS = {
    "jp" => { "EventName" => { "701" => "特殊作戦・デカグラマトン編", "801" => "桜花爛漫お祭り騒ぎ！" } }.to_json,
    "kr" => { "EventName" => { "701" => "특수 작전 데카그라마톤 편", "801" => "벚꽃만발 축제대소동!" } }.to_json,
    "en" => { "EventName" => { "701" => "Special Mission Decagrammaton", "801" => "Cherry Blossom Festival Commotion!" } }.to_json,
  }.freeze

  describe "normalized mechanics" do
    let!(:event_content) { FactoryBot.create(:event_content, uid: "801") }
    let!(:run) do
      EventContentRun.create!(event_content_uid: event_content.uid, run_type: "first", source_event_content_uid: 801, position: 0)
    end

    before do
      stage = EventContentRunStage.create!(
        event_content_run: run,
        uid: "8012301",
        stage_type: "stage",
        stage_index: 0,
        stage_number: "1",
        enter_cost_type: "currency",
        enter_cost_uid: "5",
        enter_cost_amount: 10,
        position: 0,
      )
      EventContentRunStageReward.create!(
        event_content_run_stage: stage,
        reward_type: "item",
        reward_uid: "80100",
        amount: 5,
        probability: 1,
        tag: "Default",
        position: 0,
      )
    end

    it "reads mechanics from normalized runs" do
      expect(event_content.stages(run_type: "first").first).to include(
        "uid" => "8012301",
        "stage_type" => "stage",
        "rewards" => [include("reward_uid" => "80100", "probability" => "1.0")],
      )
    end

    it "uses first-run mechanics for permanent schedules" do
      expect(event_content.stages(run_type: "permanent")).to eq(event_content.stages(run_type: "first"))
    end
  end

  describe ".sync!" do
    before do
      stub_request(:get, "https://schaledb.com/data/kr/events.min.json")
        .to_return(body: ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/events.json.gz")))
      LOCALIZATION_STUBS.each do |lang_path, body|
        stub_request(:get, "https://schaledb.com/data/#{lang_path}/localization.min.json").to_return(body: body)
      end
      allow(SchaleDB::V1::Images).to receive(:event_logo).and_return(nil)
    end

    subject(:sync) { described_class.sync! }

    it "keeps SchaleDB ownership for event records, translations, and GL/CN schedules only" do
      sync

      event = described_class.find_by!(uid: "701")
      expect(event.name).to eq("특수 작전 데카그라마톤 편")
      expect(event.name("ja")).to eq("特殊作戦・デカグラマトン編")
      expect(event.schedules.distinct.pluck(:region)).to contain_exactly("gl", "cn")
      expect(event.schedules.where(region: "jp")).to be_empty
    end

    it "is idempotent" do
      sync
      expect { sync }.not_to change { [described_class.count, EventContentSchedule.count, Translation.count] }
    end
  end
end
