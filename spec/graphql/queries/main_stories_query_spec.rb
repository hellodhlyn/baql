require "rails_helper"

RSpec.describe Queries::MainStoriesQuery, type: :graphql do
  def query
    <<~GRAPHQL
      query {
        mainStories {
          uid
          season
          label
          sortOrder
          chapters {
            uid
            chapterNumber
            parts {
              uid
              sortOrder
              schedules {
                region
                confirmed
              }
            }
          }
        }
      }
    GRAPHQL
  end

  let!(:legacy_volume) do
    FactoryBot.create(
      :main_story_volume,
      uid: "final",
      baql_id: "#{MainStoryVolume::BAQL_ID_PREFIX}final",
      season: 1,
      label: "Final.",
      sort_order: 2,
    )
  end
  let!(:season_two_volume) do
    FactoryBot.create(
      :main_story_volume,
      uid: "2-1",
      baql_id: "#{MainStoryVolume::BAQL_ID_PREFIX}2-1",
      season: 2,
      label: "Vol.1",
      sort_order: 1,
    )
  end
  let!(:legacy_chapter) do
    FactoryBot.create(
      :main_story_chapter,
      uid: "final-1",
      baql_id: "#{MainStoryChapter::BAQL_ID_PREFIX}final-1",
      volume_uid: legacy_volume.uid,
      chapter_number: 1,
    )
  end
  let!(:season_two_chapter) do
    FactoryBot.create(
      :main_story_chapter,
      uid: "2-1-1",
      baql_id: "#{MainStoryChapter::BAQL_ID_PREFIX}2-1-1",
      volume_uid: season_two_volume.uid,
      chapter_number: 1,
    )
  end
  let!(:legacy_part) do
    FactoryBot.create(
      :main_story_part,
      uid: "final-1-1",
      baql_id: "#{MainStoryPart::BAQL_ID_PREFIX}final-1-1",
      chapter_uid: legacy_chapter.uid,
      sort_order: 1,
    )
  end
  let!(:season_two_part) do
    FactoryBot.create(
      :main_story_part,
      uid: "2-1-1-1",
      baql_id: "#{MainStoryPart::BAQL_ID_PREFIX}2-1-1-1",
      chapter_uid: season_two_chapter.uid,
      sort_order: 1,
    )
  end
  let!(:season_two_schedule) do
    MainStoryPartSchedule.create!(
      part_uid: season_two_part.uid,
      region: "jp",
      released_at: Time.zone.parse("2026-04-20 12:00:00"),
      confirmed: true,
    )
  end

  it "returns the volumes ordered by season and sort_order" do
    result = execute_graphql(query)

    expect(result["data"]["mainStories"].map { |story| [story["uid"], story["season"]] }).to eq(
      [["final", 1], ["2-1", 2]]
    )
  end

  it "exposes season-aware nested story uids unchanged" do
    result = execute_graphql(query)
    season_two_story = result["data"]["mainStories"].find { |story| story["uid"] == "2-1" }

    expect(season_two_story["chapters"]).to contain_exactly(
      a_hash_including(
        "uid" => "2-1-1",
        "parts" => contain_exactly(
          a_hash_including(
            "uid" => "2-1-1-1",
            "schedules" => contain_exactly(
              a_hash_including("region" => "jp", "confirmed" => true)
            ),
          )
        ),
      )
    )
  end
end
