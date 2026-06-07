# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MiniStories::CreateMiniStory, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateMiniStoryInput!) {
        createMiniStory(input: $input) {
          miniStory {
            uid
            title
            titleEn: title(language: en)
            episodeCount
            schedules { region releasedAt }
          }
          errors
        }
      }
    GRAPHQL
  end

  it "creates a mini story with translations and schedules" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "guide-task",
        episodeCount: 4,
        title: [
          { language: "ko", value: "가이드 미션" },
          { language: "en", value: "Guide Mission" },
        ],
        schedules: [
          { region: "jp", releasedAt: "2026-03-10T02:00:00Z" },
          { region: "gl", releasedAt: "2026-04-10T02:00:00Z" },
        ],
      },
    })
    data = result.dig("data", "createMiniStory")

    expect(data["errors"]).to be_empty
    expect(data.dig("miniStory", "uid")).to eq("guide-task")
    expect(data.dig("miniStory", "title")).to eq("가이드 미션")
    expect(data.dig("miniStory", "titleEn")).to eq("Guide Mission")
    expect(data.dig("miniStory", "episodeCount")).to eq(4)
    expect(data.dig("miniStory", "schedules").map { |schedule| schedule["region"] }).to eq(%w[gl jp])
    expect(MiniStory.find_by(uid: "guide-task").title("en")).to eq("Guide Mission")
  end

  it "returns validation errors and rolls back on invalid input" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "invalid-story",
        episodeCount: 0,
        title: [{ language: "ko", value: "잘못된 스토리" }],
        schedules: [{ region: "jp", releasedAt: "2026-03-10T02:00:00Z" }],
      },
    })
    data = result.dig("data", "createMiniStory")

    expect(data["errors"]).to be_present
    expect(data["miniStory"]).to be_nil
    expect(MiniStory.find_by(uid: "invalid-story")).to be_nil
    expect(MiniStorySchedule.where(mini_story_uid: "invalid-story")).to be_empty
  end

  it "returns a friendly error when title translations are empty" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "empty-title",
        episodeCount: 1,
        title: [],
      },
    })
    data = result.dig("data", "createMiniStory")

    expect(data["errors"]).to eq(["Title must include at least one translation"])
    expect(data["miniStory"]).to be_nil
    expect(MiniStory.find_by(uid: "empty-title")).to be_nil
  end

  it "returns an error when uid is duplicated" do
    FactoryBot.create(:mini_story, uid: "duplicate-story")

    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "duplicate-story",
        episodeCount: 2,
        title: [{ language: "ko", value: "중복 스토리" }],
      },
    })
    data = result.dig("data", "createMiniStory")

    expect(data["errors"]).to be_present
    expect(data["miniStory"]).to be_nil
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: {
        uid: "no-admin",
        episodeCount: 2,
        title: [{ language: "ko", value: "권한 없음" }],
      },
    })

    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
