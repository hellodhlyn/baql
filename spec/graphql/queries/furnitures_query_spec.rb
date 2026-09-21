require "rails_helper"

RSpec.describe Queries::FurnituresQuery, type: :graphql do
  subject(:resolver) { described_class.new(object: nil, context: query_context, field: nil) }

  describe "#resolve" do
    let!(:furniture_2) { FactoryBot.create(:furniture, uid: "2") }
    let!(:furniture_1) { FactoryBot.create(:furniture, uid: "1") }

    it "returns all furnitures when uids is omitted" do
      expect(resolver.resolve.pluck(:uid)).to eq(%w[1 2])
    end

    it "returns matching furnitures when uids is present" do
      expect(resolver.resolve(uids: ["2"]).pluck(:uid)).to eq(["2"])
    end

    it "returns no furnitures when uids is explicitly empty" do
      expect(resolver.resolve(uids: [])).to be_empty
    end
  end

  describe "GraphQL execution" do
    before do
      group = FactoryBot.create(:furniture_group, uid: "100", name: "모모프렌즈 카페 세트")
      FactoryBot.create(:furniture, uid: "300", furniture_group_uid: group.uid, name: "모모 의자")
      FactoryBot.create(:furniture, uid: "301", name: "단품 의자")
    end

    it "returns furnitures with their furniture group" do
      result = execute_graphql(<<~GRAPHQL)
        query {
          furnitures {
            uid
            name
            furnitureGroup { uid name }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      furnitures = result.dig("data", "furnitures")
      expect(furnitures.map { |furniture| furniture["uid"] }).to eq(%w[300 301])
      expect(furnitures.first["furnitureGroup"]).to eq("uid" => "100", "name" => "모모프렌즈 카페 세트")
      expect(furnitures.last["furnitureGroup"]).to be_nil
    end
  end
end
