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
    expect(%w[Item Currency Equipment Furniture]).to all(
      satisfy do |type_name|
        BaqlSchema.types[type_name].fields.values_at("name", "description").all? do |field|
          field.arguments.key?("lang")
        end
      end,
    )
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

  it "exposes structured skill stat modifiers" do
    level_type = BaqlSchema.types["StudentSkillLevel"]
    modifier_type = BaqlSchema.types["StudentSkillStatModifier"]

    expect(level_type.fields.fetch("statModifiers").type.to_type_signature)
      .to eq("[StudentSkillStatModifier!]!")
    expect(modifier_type.fields).to include("stat", "kind", "value", "activation", "persistence")
  end
end
