# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MainStoryParts::UpdateMainStoryPart, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateMainStoryPartInput!) {
        updateMainStoryPart(input: $input) {
          mainStoryPart {
            uid
            sortOrder
            episodeStart
            episodeEnd
            name
            nameJa: name(language: ja)
          }
          errors
        }
      }
    GRAPHQL
  end

  let!(:chapter) { FactoryBot.create(:main_story_chapter, uid: "1-1") }
  let!(:other_chapter) { FactoryBot.create(:main_story_chapter, uid: "1-2") }
  let!(:part) do
    FactoryBot.create(:main_story_part, uid: "1-1-1", chapter_uid: chapter.uid, sort_order: 1).tap do |p|
      p.set_name("전반", "ko")
      p.set_name("Part 1", "en")
    end
  end

  it "updates provided fields without clearing omitted translations" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "1-1-1",
        chapterUid: other_chapter.uid,
        episodeStart: 1,
        episodeEnd: 4,
        name: [{ language: "ja", value: "前半" }],
      },
    })
    data = result.dig("data", "updateMainStoryPart")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryPart", "episodeStart")).to eq(1)
    expect(data.dig("mainStoryPart", "episodeEnd")).to eq(4)
    expect(data.dig("mainStoryPart", "name")).to eq("전반")
    expect(data.dig("mainStoryPart", "nameJa")).to eq("前半")
    expect(part.reload.chapter_uid).to eq(other_chapter.uid)
    expect(part.name("en")).to eq("Part 1")
  end

  it "clears a name translation when the provided value is blank" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "1-1-1",
        name: [{ language: "ko", value: " " }],
      },
    })
    data = result.dig("data", "updateMainStoryPart")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryPart", "name")).to be_nil
    expect(part.reload.name("ko")).to be_nil
    expect(part.name("en")).to eq("Part 1")
  end

  it "returns validation errors when chapter_uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "1-1-1", chapterUid: "unknown" },
    })
    data = result.dig("data", "updateMainStoryPart")

    expect(data["errors"]).to be_present
    expect(data["mainStoryPart"]).to be_nil
    expect(part.reload.chapter_uid).to eq(chapter.uid)
  end

  it "errors when uid is unknown" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "unknown" },
    })

    expect(result["errors"].first["message"]).to include("MainStoryPart with uid 'unknown' not found")
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: { uid: "1-1-1", episodeStart: 1 },
    })

    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
