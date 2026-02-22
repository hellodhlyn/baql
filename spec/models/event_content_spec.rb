require "rails_helper"

RSpec.describe EventContent, type: :model do
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
