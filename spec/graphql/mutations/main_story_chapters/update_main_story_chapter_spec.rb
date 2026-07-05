# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MainStoryChapters::UpdateMainStoryChapter, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateMainStoryChapterInput!) {
        updateMainStoryChapter(input: $input) {
          mainStoryChapter {
            uid
            chapterNumber
            name
            nameJa: name(language: ja)
          }
          errors
        }
      }
    GRAPHQL
  end

  let!(:volume) { FactoryBot.create(:main_story_volume, uid: "1") }
  let!(:other_volume) { FactoryBot.create(:main_story_volume, uid: "2") }
  let!(:chapter) do
    FactoryBot.create(:main_story_chapter, uid: "1-1", volume_uid: volume.uid, chapter_number: 1).tap do |c|
      c.set_name("1장", "ko")
      c.set_name("Chapter 1", "en")
    end
  end

  it "updates provided fields without clearing omitted translations" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "1-1",
        volumeUid: other_volume.uid,
        chapterNumber: 2,
        name: [{ language: "ja", value: "1章" }],
      },
    })
    data = result.dig("data", "updateMainStoryChapter")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryChapter", "chapterNumber")).to eq(2)
    expect(data.dig("mainStoryChapter", "name")).to eq("1장")
    expect(data.dig("mainStoryChapter", "nameJa")).to eq("1章")
    expect(chapter.reload.volume_uid).to eq(other_volume.uid)
    expect(chapter.name("en")).to eq("Chapter 1")
  end

  it "returns validation errors when volume_uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "1-1", volumeUid: "unknown" },
    })
    data = result.dig("data", "updateMainStoryChapter")

    expect(data["errors"]).to be_present
    expect(data["mainStoryChapter"]).to be_nil
    expect(chapter.reload.volume_uid).to eq(volume.uid)
  end

  it "errors when uid is unknown" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "unknown" },
    })

    expect(result["errors"].first["message"]).to include("MainStoryChapter with uid 'unknown' not found")
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: { uid: "1-1", chapterNumber: 2 },
    })

    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
