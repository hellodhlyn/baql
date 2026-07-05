# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MainStoryChapters::CreateMainStoryChapter, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateMainStoryChapterInput!) {
        createMainStoryChapter(input: $input) {
          mainStoryChapter {
            uid
            chapterNumber
            name
            nameEn: name(language: en)
          }
          errors
        }
      }
    GRAPHQL
  end

  let!(:volume) { FactoryBot.create(:main_story_volume, uid: "1") }

  it "creates a chapter with translations" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "1-5",
        volumeUid: volume.uid,
        chapterNumber: 5,
        name: [
          { language: "ko", value: "5장" },
          { language: "en", value: "Chapter 5" },
        ],
      },
    })
    data = result.dig("data", "createMainStoryChapter")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryChapter", "uid")).to eq("1-5")
    expect(data.dig("mainStoryChapter", "chapterNumber")).to eq(5)
    expect(data.dig("mainStoryChapter", "name")).to eq("5장")
    expect(data.dig("mainStoryChapter", "nameEn")).to eq("Chapter 5")
    expect(MainStoryChapter.find_by(uid: "1-5").volume_uid).to eq(volume.uid)
  end

  it "returns a friendly error when name translations are empty" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "1-6", volumeUid: volume.uid, chapterNumber: 6, name: [] },
    })
    data = result.dig("data", "createMainStoryChapter")

    expect(data["errors"]).to eq(["Name must include at least one translation"])
    expect(data["mainStoryChapter"]).to be_nil
  end

  it "returns validation errors when volume_uid does not exist" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "1-7", volumeUid: "unknown", chapterNumber: 7, name: [{ language: "ko", value: "7장" }] },
    })
    data = result.dig("data", "createMainStoryChapter")

    expect(data["errors"]).to be_present
    expect(data["mainStoryChapter"]).to be_nil
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: { uid: "1-8", volumeUid: volume.uid, chapterNumber: 8, name: [{ language: "ko", value: "권한 없음" }] },
    })

    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
