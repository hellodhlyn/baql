require "rails_helper"

RSpec.describe Queries::StudentCatalogQuery, type: :graphql do
  around do |example|
    previous = ENV["ASSET_BASE_URL"]
    ENV["ASSET_BASE_URL"] = "https://assets.example.test"
    example.run
  ensure
    ENV["ASSET_BASE_URL"] = previous
  end

  it "returns the canonical shared catalog and all student skill levels" do
    StudentCatalog.create!(
      region: "japan",
      version: "database-sha",
      client_version: "1.70.436321",
      database_sha256: "database-sha",
      data: {
        "stat_level_interpolation_end_level" => 100,
        "stat_level_interpolations" => [{
          "level" => 2,
          "ratios" => [{ "growth_type" => "standard", "value" => 101 }],
        }],
        "terrain_adaptation_factors" => [{
          "rank" => "s",
          "attack_power_factor" => 12_000,
          "accuracy_factor" => 0,
          "dodge_factor" => 0,
          "shot_factor" => 6_000,
          "block_factor" => 6_000,
        }],
        "equipment" => [],
      },
    )
    student = FactoryBot.create(
      :student,
      uid: "10122",
      catalog_data: {
        "profile" => {
          "localizations" => {
            "ko" => { "family_name" => "미소노", "personal_name" => "미카" },
            "ja" => { "family_name" => "聖園", "personal_name" => "ミカ" },
          },
        },
        "stat_profile" => {
          "growth_type" => "standard",
          "level_stats" => [{ "stat" => "attack_power", "level1" => 315, "level100" => 3155 }],
          "fixed_stats" => [{ "stat" => "accuracy_point", "value" => 514 }],
        },
        "terrain_adaptations" => { "street" => "s", "outdoor" => "a", "indoor" => "d" },
        "star_bonuses" => [],
        "potential_bonuses" => [],
        "favor_rewards" => [],
        "weapon" => {
          "localizations" => { "ko" => { "name" => "Quis ut Deus" } },
          "growth_type" => "standard",
          "level_stats" => [],
          "stages" => [],
          "image_asset_key" => "images/student-assets/weapon/ab/abcdef.webp",
        },
        "gear" => nil,
        "skill_configurations" => [{
          "form_index" => 0,
          "minimum_weapon_star" => 0,
          "minimum_gear_tier" => 0,
          "select_ex_skill_action_slot" => 1,
          "slots" => [{
            "slot" => "ex",
            "skills" => [
              { "position" => 0, "skill_uid" => "CH0294SelectEx01" },
              { "position" => 1, "skill_uid" => nil },
            ],
          }],
        }],
      },
    )
    StudentSkill.create!(
      student_uid: student.uid,
      uid: "CH0294Ex02",
      skill_type: "ex",
      name: "별의 부름",
      localizations: {
        "ko" => {
          "name" => "별의 부름",
          "description" => {
            "template" => "적 1인에게 공격력 {{1}} 대미지",
            "parameters" => [{
              "id" => 1,
              "emphasized" => true,
              "values" => [
                { "level" => 1, "text" => "827%" },
                { "level" => 2, "text" => "951%" },
              ],
            }],
          },
        },
      },
      levels: [{ "level" => 1, "cost" => 3 }, { "level" => 2, "cost" => 3 }],
      links: {
        "additional_skill_uids" => ["CH0294Ex03"],
        "selectable_skills" => [{ "condition" => "enemy", "skill_uid" => "CH0294Ex02" }],
      },
      icon_asset_key: "images/student-assets/skill/cd/cdef.webp",
    )

    result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
      query($uid: String!) {
        studentCatalog {
          version
          assetsVersion
          clientVersion
          statLevelInterpolationEndLevel
          statLevelInterpolations {
            level
            ratios { growthType value }
          }
          terrainAdaptationFactors { rank attackPowerFactor }
        }
        student(uid: $uid) {
          catalog {
            profile(lang: ja) { familyName personalName }
            profileEn: profile(lang: en) { familyName personalName }
            statProfile {
              levelStats { stat level1 level100 }
            }
            terrainAdaptations { street outdoor indoor }
            weapon { name imageUrl }
            skillConfigurations {
              formIndex
              slots {
                slot
                skills { position skillUid }
              }
            }
          }
          skills(includeVariants: true) {
            uid
            name
            iconUrl
            maxLevel
            levels { level cost }
            description {
              template
              parameters {
                id
                emphasized
                values { level text }
              }
            }
            descriptionEn: description(lang: en) { template }
            additionalSkillUids
            selectableSkills { condition skillUid }
          }
        }
      }
    GRAPHQL

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "studentCatalog")).to include(
      "version" => "database-sha",
      "assetsVersion" => nil,
      "clientVersion" => "1.70.436321",
      "statLevelInterpolationEndLevel" => 100,
    )
    expect(result.dig("data", "studentCatalog", "statLevelInterpolations", 0)).to eq(
      "level" => 2,
      "ratios" => [{ "growthType" => "STANDARD", "value" => 101 }],
    )
    expect(result.dig("data", "student", "catalog", "profile")).to eq(
      "familyName" => "聖園",
      "personalName" => "ミカ",
    )
    expect(result.dig("data", "student", "catalog", "profileEn")).to eq(
      "familyName" => "미소노",
      "personalName" => "미카",
    )
    expect(result.dig("data", "student", "catalog", "skillConfigurations", 0, "slots", 0, "skills")).to eq([
      { "position" => 0, "skillUid" => "CH0294SelectEx01" },
      { "position" => 1, "skillUid" => nil },
    ])
    expect(result.dig("data", "student", "skills", 0)).to include(
      "uid" => "CH0294Ex02",
      "iconUrl" => "https://assets.example.test/images/student-assets/skill/cd/cdef.webp",
      "maxLevel" => 2,
      "additionalSkillUids" => ["CH0294Ex03"],
    )
    expect(result.dig("data", "student", "skills", 0, "descriptionEn", "template"))
      .to eq("적 1인에게 공격력 {{1}} 대미지")
  end

  it "keeps the legacy skills field on the baseline configuration unless variants are requested" do
    student = FactoryBot.create(
      :student,
      uid: "skill-compatibility",
      catalog_data: {
        "skill_configurations" => [{
          "form_index" => 0,
          "minimum_weapon_star" => 0,
          "minimum_gear_tier" => 0,
          "slots" => [{
            "slot" => "ex",
            "skills" => [{ "position" => 0, "skill_uid" => "BaselineEx" }],
          }],
        }],
      },
    )
    %w[BaselineEx VariantEx].each do |uid|
      StudentSkill.create!(
        student_uid: student.uid,
        uid: uid,
        skill_type: "ex",
        name: uid,
      )
    end

    result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
      query($uid: String!) {
        student(uid: $uid) {
          skills { uid }
          catalogSkills: skills(includeVariants: true) { uid }
        }
      }
    GRAPHQL

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "student", "skills")).to eq([{ "uid" => "BaselineEx" }])
    expect(result.dig("data", "student", "catalogSkills").map { |skill| skill.fetch("uid") })
      .to contain_exactly("BaselineEx", "VariantEx")
  end
end
