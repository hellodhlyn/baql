# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MainStoryParts::CreateMainStoryPart, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateMainStoryPartInput!) {
        createMainStoryPart(input: $input) {
          mainStoryPart {
            uid
            sortOrder
            episodeStart
            episodeEnd
            name
            nameEn: name(language: en)
          }
          errors
        }
      }
    GRAPHQL
  end

  let!(:chapter) { FactoryBot.create(:main_story_chapter, uid: "1-1") }

  it "creates a part with translations and episode range" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "1-1-1",
        chapterUid: chapter.uid,
        sortOrder: 1,
        episodeStart: 1,
        episodeEnd: 4,
        name: [
          { language: "ko", value: "전반" },
          { language: "en", value: "Part 1" },
        ],
      },
    })
    data = result.dig("data", "createMainStoryPart")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryPart", "uid")).to eq("1-1-1")
    expect(data.dig("mainStoryPart", "episodeStart")).to eq(1)
    expect(data.dig("mainStoryPart", "episodeEnd")).to eq(4)
    expect(data.dig("mainStoryPart", "name")).to eq("전반")
    expect(data.dig("mainStoryPart", "nameEn")).to eq("Part 1")
    expect(MainStoryPart.find_by(uid: "1-1-1").chapter_uid).to eq(chapter.uid)
  end

  it "creates a part without episode numbers for unreleased content" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "1-1-2",
        chapterUid: chapter.uid,
        sortOrder: 2,
        name: [{ language: "ko", value: "후반" }],
      },
    })
    data = result.dig("data", "createMainStoryPart")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryPart", "episodeStart")).to be_nil
    expect(data.dig("mainStoryPart", "episodeEnd")).to be_nil
  end

  it "returns a friendly error when name translations are empty" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "1-1-3", chapterUid: chapter.uid, sortOrder: 3, name: [] },
    })
    data = result.dig("data", "createMainStoryPart")

    expect(data["errors"]).to eq(["Name must include at least one translation"])
    expect(data["mainStoryPart"]).to be_nil
  end

  it "returns validation errors when chapter_uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "1-1-4", chapterUid: "unknown", sortOrder: 4, name: [{ language: "ko", value: "미상" }] },
    })
    data = result.dig("data", "createMainStoryPart")

    expect(data["errors"]).to be_present
    expect(data["mainStoryPart"]).to be_nil
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: { uid: "1-1-5", chapterUid: chapter.uid, sortOrder: 5, name: [{ language: "ko", value: "권한 없음" }] },
    })

    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
