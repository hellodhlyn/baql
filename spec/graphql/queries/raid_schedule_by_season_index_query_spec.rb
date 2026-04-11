require "rails_helper"

RSpec.describe Queries::RaidScheduleBySeasonIndexQuery, type: :graphql do
  def query(region:, season_index:)
    <<~GRAPHQL
      query {
        raidScheduleBySeasonIndex(region: "#{region}", seasonIndex: #{season_index}) {
          uid
          region
          raidType
          seasonIndex
        }
      }
    GRAPHQL
  end

  describe "find by region and season index" do
    it "returns the matching schedule" do
      schedule = FactoryBot.create(
        :raid_schedule,
        uid: "jp_total_assault_10",
        region: "jp",
        season_index: 10,
      )

      result = execute_graphql(query(region: "jp", season_index: 10))
      data = result["data"]["raidScheduleBySeasonIndex"]

      expect(data).to include(
        "uid" => schedule.uid,
        "region" => "jp",
        "raidType" => "total_assault",
        "seasonIndex" => 10,
      )
    end

    it "prefers total_assault when multiple raid types share the same season index" do
      FactoryBot.create(
        :raid_schedule,
        uid: "jp_elimination_10",
        region: "jp",
        raid_type: "elimination",
        season_index: 10,
      )
      FactoryBot.create(
        :raid_schedule,
        uid: "jp_total_assault_10",
        region: "jp",
        raid_type: "total_assault",
        season_index: 10,
      )

      result = execute_graphql(query(region: "jp", season_index: 10))
      data = result["data"]["raidScheduleBySeasonIndex"]

      expect(data).to include(
        "uid" => "jp_total_assault_10",
        "raidType" => "total_assault",
      )
    end
  end

  describe "when no schedule exists" do
    it "returns null" do
      result = execute_graphql(query(region: "gl", season_index: 999))
      expect(result["data"]["raidScheduleBySeasonIndex"]).to be_nil
    end
  end
end
