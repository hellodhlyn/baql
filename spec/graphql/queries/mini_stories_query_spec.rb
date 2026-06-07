# frozen_string_literal: true

require "rails_helper"

RSpec.describe Queries::MiniStoriesQuery, type: :graphql do
  let(:query) do
    <<~GRAPHQL
      query($region: Region, $releasedAfter: ISO8601DateTime) {
        miniStories(region: $region, releasedAfter: $releasedAfter) {
          uid
          episodeCount
        }
      }
    GRAPHQL
  end

  it "returns all mini stories in creation order" do
    FactoryBot.create(:mini_story, uid: "first")
    FactoryBot.create(:mini_story, uid: "second")

    result = execute_graphql(query)
    data = result.dig("data", "miniStories")

    expect(data.map { |story| story["uid"] }).to eq(%w[first second])
  end

  it "filters by region and orders by that region's release date" do
    later = FactoryBot.create(:mini_story, uid: "later")
    earlier = FactoryBot.create(:mini_story, uid: "earlier")
    other_region = FactoryBot.create(:mini_story, uid: "other-region")
    FactoryBot.create(:mini_story_schedule, mini_story_uid: later.uid, region: "jp",
                                            released_at: Time.zone.parse("2026-05-01 02:00:00"))
    FactoryBot.create(:mini_story_schedule, mini_story_uid: earlier.uid, region: "jp",
                                            released_at: Time.zone.parse("2026-04-01 02:00:00"))
    FactoryBot.create(:mini_story_schedule, mini_story_uid: other_region.uid, region: "gl",
                                            released_at: Time.zone.parse("2026-03-01 02:00:00"))

    result = execute_graphql(query, variables: { region: "jp" })
    data = result.dig("data", "miniStories")

    expect(data.map { |story| story["uid"] }).to eq(%w[earlier later])
  end

  it "filters by releasedAfter across schedules" do
    old_story = FactoryBot.create(:mini_story, uid: "old-story")
    new_story = FactoryBot.create(:mini_story, uid: "new-story")
    FactoryBot.create(:mini_story_schedule, mini_story_uid: old_story.uid, region: "jp",
                                            released_at: Time.zone.parse("2026-03-01 02:00:00"))
    FactoryBot.create(:mini_story_schedule, mini_story_uid: new_story.uid, region: "jp",
                                            released_at: Time.zone.parse("2026-05-01 02:00:00"))

    result = execute_graphql(query, variables: { releasedAfter: "2026-04-01T00:00:00Z" })
    data = result.dig("data", "miniStories")

    expect(data.map { |story| story["uid"] }).to eq(["new-story"])
  end
end
