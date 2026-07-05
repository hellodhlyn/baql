# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MainStoryVolumes::CreateMainStoryVolume, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: CreateMainStoryVolumeInput!) {
        createMainStoryVolume(input: $input) {
          mainStoryVolume {
            uid
            season
            label
            sortOrder
            name
            nameEn: name(language: en)
          }
          errors
        }
      }
    GRAPHQL
  end

  it "creates a volume with translations" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "7",
        season: 2,
        label: "Vol.7",
        sortOrder: 7,
        name: [
          { language: "ko", value: "칠주년 이야기" },
          { language: "en", value: "Seventh Anniversary" },
        ],
      },
    })
    data = result.dig("data", "createMainStoryVolume")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryVolume", "uid")).to eq("7")
    expect(data.dig("mainStoryVolume", "season")).to eq(2)
    expect(data.dig("mainStoryVolume", "label")).to eq("Vol.7")
    expect(data.dig("mainStoryVolume", "sortOrder")).to eq(7)
    expect(data.dig("mainStoryVolume", "name")).to eq("칠주년 이야기")
    expect(data.dig("mainStoryVolume", "nameEn")).to eq("Seventh Anniversary")
    expect(MainStoryVolume.find_by(uid: "7").baql_id).to eq("#{MainStoryVolume::BAQL_ID_PREFIX}7")
  end

  it "returns a friendly error when name translations are empty" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "8", season: 2, label: "Vol.8", sortOrder: 8, name: [] },
    })
    data = result.dig("data", "createMainStoryVolume")

    expect(data["errors"]).to eq(["Name must include at least one translation"])
    expect(data["mainStoryVolume"]).to be_nil
    expect(MainStoryVolume.find_by(uid: "8")).to be_nil
  end

  it "returns validation errors when uid is duplicated" do
    FactoryBot.create(:main_story_volume, uid: "dup")

    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "dup", season: 2, label: "Vol.dup", sortOrder: 9, name: [{ language: "ko", value: "중복" }] },
    })
    data = result.dig("data", "createMainStoryVolume")

    expect(data["errors"]).to be_present
    expect(data["mainStoryVolume"]).to be_nil
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: { uid: "9", season: 2, label: "Vol.9", sortOrder: 9, name: [{ language: "ko", value: "권한 없음" }] },
    })

    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
