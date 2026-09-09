require "rails_helper"

RSpec.describe "GraphQL schema", type: :graphql do
  it "builds without duplicate visible definitions" do
    expect { BaqlSchema.to_definition }.not_to raise_error
  end

  it "exposes multilingual resource names and descriptions" do
    resource_fields = BaqlSchema.types["ResourceInterface"].fields

    expect(resource_fields.values_at("name", "description")).to all(
      satisfy do |field|
        field.arguments["lang"].type.to_type_signature == "Language" &&
          field.arguments["lang"].default_value == Constants::DEFAULT_LANGUAGE
      end,
    )
    expect(%w[Item Currency Equipment Furniture Emblem]).to all(
      satisfy do |type_name|
        BaqlSchema.types[type_name].fields.values_at("name", "description").all? do |field|
          field.arguments.key?("lang")
        end
      end,
    )
  end

  it "exposes event mission descriptions, conditions, rewards, and references" do
    expect(BaqlSchema.types["ResourceTypeEnum"].values).to include("emblem")
    expect(BaqlSchema.types["EventContent"].fields["missions"].type.to_type_signature)
      .to eq("[EventContentMission!]!")
    expect(BaqlSchema.types["EventContentMission"].fields).to include(
      "uid",
      "category",
      "resetType",
      "displayOrder",
      "description",
      "condition",
      "reward",
      "conditionReward",
      "preMissionUid",
      "completionReferenceMissionUid",
      "completionReferenceRequiredCount",
      "completionExtension",
    )
    expect(BaqlSchema.types["EventContentMissionDescription"].fields).to include("template", "parameters")
    expect(BaqlSchema.types["EventContentMissionCondition"].fields).to include("type", "count", "parameters", "parameterTags")
    expect(BaqlSchema.types["EventContentMissionReward"].fields).to include("resource", "amount")
    image_field = BaqlSchema.types["Emblem"].fields.fetch("imageUrl")
    expect(image_field.arguments.fetch("lang").type.to_type_signature).to eq("Language")
    expect(image_field.arguments.fetch("lang").default_value).to eq(Constants::DEFAULT_LANGUAGE)
  end

  it "marks legacy minigame payment fields as deprecated" do
    config_type = BaqlSchema.types["EventMinigameConfig"]
    group_type = BaqlSchema.types["EventMinigameRewardGroup"]

    expect(config_type.fields["payment"].deprecation_reason).to include("Use `payments`")
    expect(group_type.fields["payment"].deprecation_reason).to include("Use `payments`")
  end

  it "exposes event shop purchase tiers" do
    shop_resource_type = BaqlSchema.types["EventContentShopResource"]
    purchase_tier_type = BaqlSchema.types["EventContentShopResourcePurchaseTier"]

    expect(shop_resource_type.fields).to include("purchaseTiers")
    expect(purchase_tier_type.fields).to include(
      "tierIndex",
      "startQuantity",
      "quantity",
      "unitPrice",
      "paymentResource",
    )
  end

  it "exposes whether payment range quantities vary" do
    payment_range_type = BaqlSchema.types["EventMinigamePaymentRange"]

    expect(payment_range_type.fields).to include("quantityVariable")
  end

  it "exposes student characters and variants" do
    student_type = BaqlSchema.types["Student"]
    character_type = BaqlSchema.types["StudentCharacter"]
    variant_type = BaqlSchema.types["StudentVariant"]

    expect(student_type.fields).to include("character", "studentVariant")
    expect(character_type.fields).to include("uid", "studentVariants")
    expect(variant_type.fields).to include("uid", "isMulticlass", "primaryStudent", "students")
  end

  it "exposes nullable student clubs with localized names" do
    student_type = BaqlSchema.types["Student"]
    club_type = BaqlSchema.types["StudentClub"]
    name_field = club_type.fields.fetch("name")

    expect(student_type.fields.fetch("club").type.to_type_signature).to eq("StudentClub")
    expect(club_type.fields).to include("uid", "name")
    expect(name_field.arguments.fetch("lang").type.to_type_signature).to eq("Language")
    expect(name_field.arguments.fetch("lang").default_value).to eq(Constants::DEFAULT_LANGUAGE)
  end

  it "exposes structured skill stat modifiers" do
    level_type = BaqlSchema.types["StudentSkillLevel"]
    modifier_type = BaqlSchema.types["StudentSkillStatModifier"]

    expect(level_type.fields.fetch("statModifiers").type.to_type_signature)
      .to eq("[StudentSkillStatModifier!]!")
    expect(modifier_type.fields).to include("stat", "kind", "value", "activation", "persistence")
  end
end
