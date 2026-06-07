# frozen_string_literal: true

require "rails_helper"

RSpec.describe Queries::MiniStoryQuery, type: :graphql do
  let(:query) do
    <<~GRAPHQL
      query($uid: String!) {
        miniStory(uid: $uid) {
          uid
          title
          titleEn: title(language: en)
          episodeCount
          schedules {
            region
            releasedAt
          }
        }
      }
    GRAPHQL
  end

  it "returns a mini story with translated title and schedules" do
    story = FactoryBot.create(:mini_story, uid: "guide-task", episode_count: 4)
    story.set_title("가이드 미션", "ko")
    story.set_title("Guide Mission", "en")
    FactoryBot.create(:mini_story_schedule, mini_story_uid: story.uid, region: "gl",
                                            released_at: Time.zone.parse("2026-04-10 02:00:00"))
    FactoryBot.create(:mini_story_schedule, mini_story_uid: story.uid, region: "jp",
                                            released_at: Time.zone.parse("2026-03-10 02:00:00"))

    result = execute_graphql(query, variables: { uid: "guide-task" })
    data = result.dig("data", "miniStory")

    expect(data["uid"]).to eq("guide-task")
    expect(data["title"]).to eq("가이드 미션")
    expect(data["titleEn"]).to eq("Guide Mission")
    expect(data["episodeCount"]).to eq(4)
    expect(data["schedules"].map { |schedule| schedule["region"] }).to eq(%w[gl jp])
    expect(data["schedules"].first["releasedAt"]).to eq("2026-04-10T02:00:00Z")
  end

  it "returns null for an unknown uid" do
    result = execute_graphql(query, variables: { uid: "unknown" })

    expect(result.dig("data", "miniStory")).to be_nil
  end
end
