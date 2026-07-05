# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mutations::MainStoryVolumes::UpdateMainStoryVolume, type: :graphql do
  let(:mutation) do
    <<~GRAPHQL
      mutation($input: UpdateMainStoryVolumeInput!) {
        updateMainStoryVolume(input: $input) {
          mainStoryVolume {
            uid
            season
            label
            sortOrder
            name
            nameJa: name(language: ja)
          }
          errors
        }
      }
    GRAPHQL
  end

  let!(:volume) do
    FactoryBot.create(:main_story_volume, uid: "3", season: 1, label: "Vol.3", sort_order: 3).tap do |v|
      v.set_name("3권", "ko")
      v.set_name("Volume 3", "en")
    end
  end

  it "updates provided fields without clearing omitted translations" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: {
        uid: "3",
        label: "Vol.3改",
        sortOrder: 4,
        name: [{ language: "ja", value: "3巻" }],
      },
    })
    data = result.dig("data", "updateMainStoryVolume")

    expect(data["errors"]).to be_empty
    expect(data.dig("mainStoryVolume", "season")).to eq(1)
    expect(data.dig("mainStoryVolume", "label")).to eq("Vol.3改")
    expect(data.dig("mainStoryVolume", "sortOrder")).to eq(4)
    expect(data.dig("mainStoryVolume", "name")).to eq("3권")
    expect(data.dig("mainStoryVolume", "nameJa")).to eq("3巻")
    expect(volume.reload.name("en")).to eq("Volume 3")
  end

  it "returns validation errors on invalid updates" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "3", label: "" },
    })
    data = result.dig("data", "updateMainStoryVolume")

    expect(data["errors"]).to be_present
    expect(data["mainStoryVolume"]).to be_nil
    expect(volume.reload.label).to eq("Vol.3")
  end

  it "errors when uid is unknown" do
    result = execute_graphql_as_admin(mutation, variables: {
      input: { uid: "unknown" },
    })

    expect(result["errors"].first["message"]).to include("MainStoryVolume with uid 'unknown' not found")
  end

  it "requires admin context" do
    result = execute_graphql(mutation, variables: {
      input: { uid: "3", label: "Vol.3改" },
    })

    expect(result["errors"].first["message"]).to include("Authentication required")
  end
end
