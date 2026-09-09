require "rails_helper"

RSpec.describe "EventContent missions", type: :graphql do
  around do |example|
    previous = ENV["ASSET_BASE_URL"]
    ENV["ASSET_BASE_URL"] = "https://assets.example.test"
    example.run
  ensure
    ENV["ASSET_BASE_URL"] = previous
  end

  let!(:emblem) do
    FactoryBot.create(
      :emblem,
      uid: "3000845",
      name: "이벤트 엠블럼",
      description: "설명",
      image_asset_keys: {
        "ko" => "images/resources/emblems/3000845/background/ko.webp",
        "ja" => "images/resources/emblems/3000845/background/ja.webp",
      },
    )
  end

  let!(:currency) do
    FactoryBot.create(:currency, uid: "1", name: "크레딧")
  end

  let!(:event_content) do
    FactoryBot.create(:event_content, uid: "845").tap do |event|
      first = EventContentRun.create!(
        event_content_uid: event.uid,
        run_type: "first",
        source_event_content_uid: 845,
        position: 0,
      )
      rerun = EventContentRun.create!(
        event_content_uid: event.uid,
        run_type: "rerun",
        source_event_content_uid: 10_845,
        position: 1,
      )
      EventContentRunMission.create!(
        event_content_run: first,
        uid: "845005",
        category: "event_achievement",
        reset_type: "none",
        display_order: 1,
        position: 0,
        localizations: {
          "ko" => {
            "template" => "{{1}} 클리어",
            "parameters" => [{ "id" => 1, "text" => "Story", "emphasized" => true }],
          },
          "ja" => {
            "template" => "{{1}}をクリア",
            "parameters" => [{ "id" => 1, "text" => "Story", "emphasized" => true }],
          },
        },
        condition_type: "reset_complete_stage",
        condition_count: 24,
        condition_parameters: ["8451301"],
        condition_parameter_tags: [],
        reward_type: "emblem",
        reward_uid: emblem.uid,
        reward_amount: 1,
        completion_reference_required_count: 0,
        completion_extension: true,
      )
      EventContentRunMission.create!(
        event_content_run: rerun,
        uid: "10845005",
        category: "event_achievement",
        reset_type: "none",
        display_order: 1,
        position: 0,
        localizations: {
          "ko" => { "template" => "완료", "parameters" => [] },
          "ja" => { "template" => "完了", "parameters" => [] },
        },
        condition_type: "reset_complete_stage",
        condition_count: 24,
        condition_parameters: ["108451301"],
        condition_parameter_tags: [],
        reward_type: "emblem",
        reward_uid: emblem.uid,
        reward_amount: 1,
        condition_reward_type: "currency",
        condition_reward_uid: currency.uid,
        condition_reward_amount: 30_000,
        completion_reference_mission_uid: "845005",
        completion_reference_required_count: 1,
        completion_extension: true,
      )
    end
  end

  it "serves ordered missions, cross-run references, and emblem resources" do
    result = execute_graphql(<<~GRAPHQL, variables: { uid: event_content.uid })
      query($uid: String!) {
        eventContent(uid: $uid) {
          missions(runType: rerun) {
            uid
            category
            resetType
            displayOrder
            description { template parameters { id text emphasized } }
            condition { type count parameters parameterTags }
            reward {
              amount
              resource {
                __typename
                uid
                type
                name
                ... on Emblem { imageUrl imageUrlJa: imageUrl(lang: ja) }
              }
            }
            conditionReward { amount resource { __typename uid } }
            preMissionUid
            completionReferenceMissionUid
            completionReferenceRequiredCount
            completionExtension
          }
          permanent: missions(runType: permanent) { uid }
        }
      }
    GRAPHQL

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "eventContent", "missions")).to eq([
      {
        "uid" => "10845005",
        "category" => "eventAchievement",
        "resetType" => "none",
        "displayOrder" => 1,
        "description" => { "template" => "완료", "parameters" => [] },
        "condition" => { "type" => "reset_complete_stage", "count" => 24, "parameters" => ["108451301"], "parameterTags" => [] },
        "reward" => {
          "amount" => 1,
          "resource" => {
            "__typename" => "Emblem",
            "uid" => emblem.uid,
            "type" => "emblem",
            "name" => "이벤트 엠블럼",
            "imageUrl" => "https://assets.example.test/images/resources/emblems/3000845/background/ko.webp",
            "imageUrlJa" => "https://assets.example.test/images/resources/emblems/3000845/background/ja.webp",
          },
        },
        "conditionReward" => { "amount" => 30_000, "resource" => { "__typename" => "Currency", "uid" => currency.uid } },
        "preMissionUid" => nil,
        "completionReferenceMissionUid" => "845005",
        "completionReferenceRequiredCount" => 1,
        "completionExtension" => true,
      },
    ])
    expect(result.dig("data", "eventContent", "permanent")).to eq([{ "uid" => "845005" }])
  end

  it "falls back to Korean mission descriptions and keeps list SQL constant" do
    mission = EventContentRunMission.where(uid: "10845005").first
    mission.update!(localizations: { "ko" => { "template" => "한국어", "parameters" => [] } })

    query = <<~GRAPHQL
      query($uid: String!) {
        eventContent(uid: $uid) {
          missions(runType: rerun) { uid description(lang: ja) { template } }
        }
      }
    GRAPHQL

    result, queries = capture_sql do
      execute_graphql(query, variables: { uid: event_content.uid })
    end

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "eventContent", "missions")).to eq([{ "uid" => "10845005", "description" => { "template" => "한국어" } }])

    rerun = event_content.event_content_runs.find_by!(run_type: "rerun")
    20.times do |index|
      FactoryBot.create(
        :event_content_run_mission,
        event_content_run: rerun,
        uid: "additional-#{index}",
        display_order: index + 2,
        position: index + 1,
      )
    end

    larger_result, queries_with_more_missions = capture_sql do
      execute_graphql(query, variables: { uid: event_content.uid })
    end

    expect(larger_result["errors"]).to be_nil
    expect(larger_result.dig("data", "eventContent", "missions").size).to eq(21)
    expect(queries_with_more_missions.size).to eq(queries.size)
  end

  it "falls back to the Japanese Emblem background when Korean is unavailable" do
    emblem.update!(
      image_asset_keys: { "ja" => "images/resources/emblems/3000845/background/ja.webp" },
    )

    result = execute_graphql(<<~GRAPHQL, variables: { uid: event_content.uid })
      query($uid: String!) {
        eventContent(uid: $uid) {
          missions(runType: rerun) {
            reward { resource { ... on Emblem { imageUrl } } }
          }
        }
      }
    GRAPHQL

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "eventContent", "missions", 0, "reward", "resource", "imageUrl"))
      .to eq("https://assets.example.test/images/resources/emblems/3000845/background/ja.webp")
  end
end
