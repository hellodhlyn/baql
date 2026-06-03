require "rails_helper"

RSpec.describe RaidSchedule, type: :model do
  describe "defense type compatibility accessors" do
    let(:boss) { FactoryBot.create(:raid_boss, uid: "drumbarka", raid_type: "raid") }

    it "reads grouped defense type sets from the existing defense_types column" do
      schedule = FactoryBot.create(
        :raid_schedule,
        raid_boss: boss,
        uid: "jp_total_assault_90",
        season_index: 90,
        defense_types: [
          { "defense_types" => ["light", "special"], "difficulty" => "lunatic" },
        ],
      )

      expect(schedule.defense_type_sets).to contain_exactly(
        RaidSchedule::DefenseTypeSet.new(defense_types: ["light", "special"], difficulty: "lunatic"),
      )
    end

    it "flattens grouped records through the legacy defense_types accessor" do
      schedule = FactoryBot.create(
        :raid_schedule,
        raid_boss: boss,
        uid: "jp_total_assault_91",
        season_index: 91,
        defense_types: [
          { "defense_types" => ["light", "special"], "difficulty" => "lunatic" },
        ],
      )

      expect(schedule.defense_types).to contain_exactly(
        RaidSchedule::DefenseType.new(defense_type: "light", difficulty: "lunatic"),
        RaidSchedule::DefenseType.new(defense_type: "special", difficulty: "lunatic"),
      )
    end

    it "keeps legacy assignments as legacy raw JSON for backward compatibility" do
      schedule = FactoryBot.build(:raid_schedule, raid_boss: boss)

      schedule.defense_types = [
        RaidSchedule::DefenseType.new(defense_type: "heavy", difficulty: "torment"),
      ]

      expect(schedule.read_attribute(:defense_types)).to eq([
        { "defense_type" => "heavy", "difficulty" => "torment" },
      ])
      expect(schedule.defense_type_sets).to contain_exactly(
        RaidSchedule::DefenseTypeSet.new(defense_types: ["heavy"], difficulty: "torment"),
      )
    end

    it "writes grouped assignments into the reused defense_types column" do
      schedule = FactoryBot.build(:raid_schedule, raid_boss: boss)

      schedule.defense_type_sets = [
        RaidSchedule::DefenseTypeSet.new(defense_types: ["light", "special"], difficulty: "lunatic"),
      ]

      expect(schedule.read_attribute(:defense_types)).to eq([
        { "defense_types" => ["light", "special"], "difficulty" => "lunatic" },
      ])
    end

    it "rejects grouped assignments without defense types" do
      schedule = FactoryBot.build(:raid_schedule, raid_boss: boss)

      expect do
        schedule.defense_type_sets = [
          RaidSchedule::DefenseTypeSet.new(defense_types: [], difficulty: "lunatic"),
        ]
      end.to raise_error(ArgumentError, "defense_types must not be empty")
    end
  end
end
