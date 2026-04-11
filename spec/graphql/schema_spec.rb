require "rails_helper"

RSpec.describe "GraphQL schema", type: :graphql do
  it "builds without duplicate visible definitions" do
    expect { BaqlSchema.to_definition }.not_to raise_error
  end
end
