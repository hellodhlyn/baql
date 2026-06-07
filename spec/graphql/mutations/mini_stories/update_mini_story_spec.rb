# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MiniStories::UpdateMiniStory, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateMiniStoryInput!) {
        updateMiniStory(input: $input) {
          miniStory {
            uid
            title
            titleJa: title(language: ja)
            episodeCount
            schedules { region releasedAt }
          }
          errors
        }
      }
    GRAPHQL
  end

  let!(:story) do
    FactoryBot.create(:mini_story, uid: "guide-task", episode_count: 4).tap do |mini_story|
      mini_story.set_title("가이드 미션", "ko")
      mini_story.set_title("Guide Mission", "en")
    end
  end

  before do
    FactoryBot.create(:mini_story_schedule, mini_story_uid: story.uid, region: "jp",
                                            released_at: Time.zone.parse("2026-03-10 02:00:00"))
  end

  it "updates provided fields without clearing omitted translations" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "guide-task",
        episodeCount: 5,
        title: [{ language: "ja", value: "ガイドミッション" }],
        schedules: [
          { region: "jp", releasedAt: "2026-03-11T02:00:00Z" },
          { region: "gl", releasedAt: "2026-04-10T02:00:00Z" },
        ],
      },
    })
    data = result.dig("data", "updateMiniStory")

    expect(data["errors"]).to be_empty
    expect(data.dig("miniStory", "episodeCount")).to eq(5)
    expect(data.dig("miniStory", "title")).to eq("가이드 미션")
    expect(data.dig("miniStory", "titleJa")).to eq("ガイドミッション")
    expect(story.reload.title("en")).to eq("Guide Mission")
    expect(story.episode_count).to eq(5)
    expect(MiniStorySchedule.find_by(mini_story_uid: story.uid, region: "jp").released_at).to eq(Time.zone.parse("2026-03-11 02:00:00"))
    expect(MiniStorySchedule.find_by(mini_story_uid: story.uid, region: "gl").released_at).to eq(Time.zone.parse("2026-04-10 02:00:00"))
  end

  it "returns validation errors on invalid updates" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "guide-task",
        episodeCount: 0,
      },
    })
    data = result.dig("data", "updateMiniStory")

    expect(data["errors"]).to be_present
    expect(data["miniStory"]).to be_nil
    expect(story.reload.episode_count).to eq(4)
  end

  it "errors when uid is unknown" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "unknown" },
    })

    expect(result["errors"].first["message"]).to include("MiniStory with uid 'unknown' not found")
  end
end
