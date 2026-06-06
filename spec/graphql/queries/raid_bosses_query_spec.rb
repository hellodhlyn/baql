require "rails_helper"

RSpec.describe Queries::RaidBossesQuery, type: :graphql do
  def raids_admin_query
    <<~GRAPHQL
      query {
        eventContents {
          uid
          name
        }
        raidBosses(first: 100) {
          nodes {
            uid
            name
            raidType
            eventContent {
              uid
              name
            }
            schedules {
              uid
              region
              raidType
              seasonIndex
              jpSchedule {
                seasonIndex
              }
              terrain
              startAt
              endAt
              attackType
              defenseTypeSets {
                defenseTypes
                difficulty
              }
            }
          }
        }
      }
    GRAPHQL
  end

  def create_raid_admin_data(count, offset: 0)
    count.times do |index|
      uid_index = offset + index
      event_content = FactoryBot.create(:event_content, uid: "event-#{uid_index}")
      event_content.set_name("이벤트 #{uid_index}", "ko")

      boss = FactoryBot.create(
        :raid_boss,
        uid: "boss-#{uid_index}",
        event_content_uid: event_content.uid,
      )
      boss.set_name("보스 #{uid_index}", "ko")

      jp_schedule = FactoryBot.create(
        :raid_schedule,
        raid_boss: boss,
        uid: "jp_total_assault_#{uid_index + 1}",
        raid_boss_uid: boss.uid,
        region: "jp",
        raid_type: "total_assault",
        season_index: uid_index + 1,
      )

      FactoryBot.create(
        :raid_schedule,
        raid_boss: boss,
        uid: "gl_total_assault_#{uid_index + 1}",
        raid_boss_uid: boss.uid,
        region: "gl",
        raid_type: "total_assault",
        season_index: uid_index + 1,
        jp_season_index: jp_schedule.season_index,
      )
    end
  end

  it "returns the same raid admin data through batched fields" do
    create_raid_admin_data(1)

    result = execute_graphql(raids_admin_query)

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "eventContents")).to contain_exactly(
      a_hash_including("uid" => "event-0", "name" => "이벤트 0")
    )

    boss = result.dig("data", "raidBosses", "nodes").first
    expect(boss).to include(
      "uid" => "boss-0",
      "name" => "보스 0",
      "raidType" => "raid",
      "eventContent" => a_hash_including("uid" => "event-0", "name" => "이벤트 0"),
    )

    schedules_by_uid = boss["schedules"].index_by { |schedule| schedule["uid"] }
    expect(schedules_by_uid["jp_total_assault_1"]).to include(
      "region" => "jp",
      "raidType" => "total_assault",
      "seasonIndex" => 1,
      "jpSchedule" => nil,
      "terrain" => "indoor",
      "attackType" => "piercing",
      "defenseTypeSets" => contain_exactly(
        { "defenseTypes" => ["special"], "difficulty" => "lunatic" }
      ),
    )
    expect(schedules_by_uid["gl_total_assault_1"]).to include(
      "region" => "gl",
      "raidType" => "total_assault",
      "seasonIndex" => 1,
      "jpSchedule" => { "seasonIndex" => 1 },
    )
  end

  it "does not grow SQL count with the number of raid bosses" do
    create_raid_admin_data(2)

    result, queries = capture_sql do
      execute_graphql(raids_admin_query)
    end

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "raidBosses", "nodes").size).to eq(2)

    create_raid_admin_data(4, offset: 2)

    result_with_more_bosses, queries_with_more_bosses = capture_sql do
      execute_graphql(raids_admin_query)
    end

    expect(result_with_more_bosses["errors"]).to be_nil
    expect(result_with_more_bosses.dig("data", "raidBosses", "nodes").size).to eq(6)
    expect(queries_with_more_bosses.size).to eq(queries.size)
  end
end
