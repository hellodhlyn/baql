require "rails_helper"

RSpec.describe RaidBoss, type: :model do
  describe ".sync!" do
    it "stores one total-assault difficulty with multiple simultaneous defense types" do
      raid_data = {
        "Raid" => [
          {
            "Id" => 99,
            "PathName" => "drumbarka",
            "Name" => "드럼바르카",
            "ArmorType" => ["LightArmor", "Unarmed"],
            "BulletTypeInsane" => "Mystic",
          },
        ],
        "RaidSeasons" => [
          {
            "Seasons" => [
              {
                "SeasonDisplay" => "90",
                "RaidId" => 99,
                "Terrain" => "Indoor",
                "Start" => 1_780_000_000,
                "End" => 1_780_604_800,
              },
            ],
            "EliminateSeasons" => [],
          },
          {
            "Seasons" => [],
            "EliminateSeasons" => [],
          },
        ],
        "MultiFloorRaid" => [],
        "InteractiveWorldRaid" => [],
        "WorldRaid" => [],
      }

      allow(SchaleDB::V1::Data).to receive(:raids).and_return(raid_data)

      described_class.sync!

      schedule = RaidSchedule.find_by!(region: "jp", raid_type: "total_assault", season_index: 90)
      expect(schedule.raid_boss_uid).to eq("drumbarka")
      expect(schedule.read_attribute(:defense_types)).to eq([
        { "defense_types" => ["light", "special"], "difficulty" => "lunatic" },
      ])
      expect(schedule.defense_types).to contain_exactly(
        RaidSchedule::DefenseType.new(defense_type: "light", difficulty: "lunatic"),
        RaidSchedule::DefenseType.new(defense_type: "special", difficulty: "lunatic"),
      )
    end
  end
end
