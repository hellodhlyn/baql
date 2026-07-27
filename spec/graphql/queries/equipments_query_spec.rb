require "rails_helper"

RSpec.describe Queries::EquipmentsQuery, type: :graphql do
  subject(:resolver) { described_class.new(object: nil, context: query_context, field: nil) }

  describe "#resolve" do
    let!(:equipment_2) { FactoryBot.create(:equipment, uid: "2", name: "두 번째 장비") }
    let!(:equipment_1) { FactoryBot.create(:equipment, uid: "1", name: "첫 번째 장비") }

    it "returns all equipments when uids is omitted" do
      expect(resolver.resolve.pluck(:uid)).to eq(%w[1 2])
    end

    it "returns matching equipments when uids is present" do
      expect(resolver.resolve(uids: ["2"]).pluck(:uid)).to eq(["2"])
    end

    it "returns no equipments when uids is explicitly empty" do
      expect(resolver.resolve(uids: [])).to be_empty
    end
  end

  describe "GraphQL execution" do
    before do
      FactoryBot.create(:equipment, uid: "1", name: "첫 번째 장비")
      FactoryBot.create(:equipment, uid: "2", name: "두 번째 장비")
      FactoryBot.create(:equipment, uid: "3", name: "세 번째 장비")
    end

    it "returns all equipments when uids is omitted" do
      result = execute_graphql(<<~GRAPHQL)
        query {
          equipments {
            uid
            name
            rarity
            category
            subCategory
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "equipments").map { |equipment| equipment["uid"] }).to eq(%w[1 2 3])
    end
  end
end
