require "rails_helper"

RSpec.describe Raid, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "#defense_types" do
    let(:raid) { FactoryBot.create(:raid, defense_types: [
      { defense_type: "light", difficulty: nil },
      { defense_type: "special", difficulty: nil },
      { defense_type: "elastic", difficulty: nil },
    ]) }

    context "when called with new `defense_types` column" do
      it "returns the first defense type" do
        expect(raid.defense_types).to be_an(Array)
        expect(raid.defense_types.size).to eq(3)
        expect(raid.defense_types.first.defense_type).to eq("light")
      end
    end
  end

  describe ".ongoing" do
    let(:current_time) { Time.zone.parse("2025-02-28 12:00:00") }

    before do
      travel_to(current_time)
    end

    after do
      travel_back
    end

    it "returns raids that are currently ongoing" do
      ongoing_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-02-25 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.ongoing).to include(ongoing_raid)
    end

    it "includes raids that start exactly at current time" do
      raid_starting_now = FactoryBot.create(:raid,
        since: current_time,
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.ongoing).to include(raid_starting_now)
    end

    it "includes raids that end exactly at current time" do
      raid_ending_now = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-02-25 02:00:00"),
        until: current_time
      )

      expect(Raid.ongoing).to include(raid_ending_now)
    end

    it "excludes raids that have not started yet" do
      upcoming_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-03-01 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.ongoing).not_to include(upcoming_raid)
    end

    it "excludes raids that have already ended" do
      past_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-02-20 02:00:00"),
        until: Time.zone.parse("2025-02-25 02:00:00")
      )

      expect(Raid.ongoing).not_to include(past_raid)
    end

    it "returns empty array when no raids are ongoing" do
      FactoryBot.create(:raid,
        uid: "20250301-upcoming-raid",
        since: Time.zone.parse("2025-03-01 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )
      FactoryBot.create(:raid,
        uid: "20250220-past-raid",
        since: Time.zone.parse("2025-02-20 02:00:00"),
        until: Time.zone.parse("2025-02-25 02:00:00")
      )

      expect(Raid.ongoing).to be_empty
    end
  end

  describe ".upcoming" do
    let(:current_time) { Time.zone.parse("2025-02-28 12:00:00") }

    before do
      travel_to(current_time)
    end

    after do
      travel_back
    end

    it "returns raids that start in the future" do
      upcoming_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-03-01 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.upcoming).to include(upcoming_raid)
    end

    it "excludes raids that start exactly at current time" do
      raid_starting_now = FactoryBot.create(:raid,
        since: current_time,
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.upcoming).not_to include(raid_starting_now)
    end

    it "excludes raids that have already started" do
      ongoing_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-02-25 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.upcoming).not_to include(ongoing_raid)
    end

    it "excludes raids that have already ended" do
      past_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-02-20 02:00:00"),
        until: Time.zone.parse("2025-02-25 02:00:00")
      )

      expect(Raid.upcoming).not_to include(past_raid)
    end

    it "returns empty array when no raids are upcoming" do
      FactoryBot.create(:raid,
        uid: "20250225-ongoing-raid",
        since: Time.zone.parse("2025-02-25 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )
      FactoryBot.create(:raid,
        uid: "20250220-past-raid",
        since: Time.zone.parse("2025-02-20 02:00:00"),
        until: Time.zone.parse("2025-02-25 02:00:00")
      )

      expect(Raid.upcoming).to be_empty
    end
  end

  describe ".past" do
    let(:current_time) { Time.zone.parse("2025-02-28 12:00:00") }

    before do
      travel_to(current_time)
    end

    after do
      travel_back
    end

    it "returns raids that have already ended" do
      past_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-02-20 02:00:00"),
        until: Time.zone.parse("2025-02-25 02:00:00")
      )

      expect(Raid.past).to include(past_raid)
    end

    it "excludes raids that end exactly at current time" do
      raid_ending_now = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-02-25 02:00:00"),
        until: current_time
      )

      expect(Raid.past).not_to include(raid_ending_now)
    end

    it "excludes raids that are currently ongoing" do
      ongoing_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-02-25 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.past).not_to include(ongoing_raid)
    end

    it "excludes raids that have not started yet" do
      upcoming_raid = FactoryBot.create(:raid,
        since: Time.zone.parse("2025-03-01 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.past).not_to include(upcoming_raid)
    end

    it "returns empty array when no raids are past" do
      FactoryBot.create(:raid,
        uid: "20250225-ongoing-raid",
        since: Time.zone.parse("2025-02-25 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )
      FactoryBot.create(:raid,
        uid: "20250301-upcoming-raid",
        since: Time.zone.parse("2025-03-01 02:00:00"),
        until: Time.zone.parse("2025-03-03 19:00:00")
      )

      expect(Raid.past).to be_empty
    end
  end
end
