require "rails_helper"

RSpec.describe "GraphQL schema", type: :graphql do
  it "builds without duplicate visible definitions" do
    expect { BaqlSchema.to_definition }.not_to raise_error
  end

  it "marks legacy minigame payment fields as deprecated" do
    config_type = BaqlSchema.types["EventMinigameConfig"]
    group_type = BaqlSchema.types["EventMinigameRewardGroup"]

    expect(config_type.fields["payment"].deprecation_reason).to include("Use `payments`")
    expect(group_type.fields["payment"].deprecation_reason).to include("Use `payments`")
  end

  it "exposes whether payment range quantities vary" do
    payment_range_type = BaqlSchema.types["EventMinigamePaymentRange"]

    expect(payment_range_type.fields).to include("quantityVariable")
  end
end
