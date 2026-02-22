require "rails_helper"

RSpec.describe Event, type: :model do
  include ActiveSupport::Testing::TimeHelpers

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

  describe "#sync_stages!" do
    before do
      stub_request(:get, "https://schaledb.com/data/kr/events.min.json")
        .to_return(body: ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/events.json.gz")))

      stub_request(:get, "https://schaledb.com/data/kr/items.min.json")
        .to_return(body: File.read("spec/_fixtures/items.min.json"))
    end

    subject { event.sync_stages! }

    context "if event_index presents and the event is not rerun" do
      let(:event) { FactoryBot.create(:event, event_index: 809) }

      it "should sync stages" do
        expect { subject }.to change { EventStage.count }.by(17)
      end
    end
  end

  describe ".ongoing" do
    let(:current_time) { Time.zone.parse("2024-08-25 12:00:00") }

    before do
      travel_to(current_time)
    end

    after do
      travel_back
    end

    it "returns events that are currently ongoing" do
      ongoing_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-20 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.ongoing).to include(ongoing_event)
    end

    it "includes events that start exactly at current time" do
      event_starting_now = FactoryBot.create(:event,
        since: current_time,
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.ongoing).to include(event_starting_now)
    end

    it "includes events that end exactly at current time" do
      event_ending_now = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-20 02:00:00"),
        until: current_time
      )

      expect(Event.ongoing).to include(event_ending_now)
    end

    it "excludes events that have not started yet" do
      upcoming_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-26 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.ongoing).not_to include(upcoming_event)
    end

    it "excludes events that have already ended" do
      past_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-10 02:00:00"),
        until: Time.zone.parse("2024-08-20 02:00:00")
      )

      expect(Event.ongoing).not_to include(past_event)
    end

    it "returns empty array when no events are ongoing" do
      FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-26 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )
      FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-10 02:00:00"),
        until: Time.zone.parse("2024-08-20 02:00:00")
      )

      expect(Event.ongoing).to be_empty
    end
  end

  describe ".upcoming" do
    let(:current_time) { Time.zone.parse("2024-08-25 12:00:00") }

    before do
      travel_to(current_time)
    end

    after do
      travel_back
    end

    it "returns events that start in the future" do
      upcoming_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-26 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.upcoming).to include(upcoming_event)
    end

    it "excludes events that start exactly at current time" do
      event_starting_now = FactoryBot.create(:event,
        since: current_time,
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.upcoming).not_to include(event_starting_now)
    end

    it "excludes events that have already started" do
      ongoing_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-20 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.upcoming).not_to include(ongoing_event)
    end

    it "excludes events that have already ended" do
      past_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-10 02:00:00"),
        until: Time.zone.parse("2024-08-20 02:00:00")
      )

      expect(Event.upcoming).not_to include(past_event)
    end

    it "returns empty array when no events are upcoming" do
      FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-20 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )
      FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-10 02:00:00"),
        until: Time.zone.parse("2024-08-20 02:00:00")
      )

      expect(Event.upcoming).to be_empty
    end
  end

  describe ".past" do
    let(:current_time) { Time.zone.parse("2024-08-25 12:00:00") }

    before do
      travel_to(current_time)
    end

    after do
      travel_back
    end

    it "returns events that have already ended" do
      past_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-10 02:00:00"),
        until: Time.zone.parse("2024-08-20 02:00:00")
      )

      expect(Event.past).to include(past_event)
    end

    it "excludes events that end exactly at current time" do
      event_ending_now = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-20 02:00:00"),
        until: current_time
      )

      expect(Event.past).not_to include(event_ending_now)
    end

    it "excludes events that are currently ongoing" do
      ongoing_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-20 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.past).not_to include(ongoing_event)
    end

    it "excludes events that have not started yet" do
      upcoming_event = FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-26 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.past).not_to include(upcoming_event)
    end

    it "returns empty array when no events are past" do
      FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-20 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )
      FactoryBot.create(:event,
        since: Time.zone.parse("2024-08-26 02:00:00"),
        until: Time.zone.parse("2024-09-03 02:00:00")
      )

      expect(Event.past).to be_empty
    end
  end
end
