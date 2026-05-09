require "rails_helper"

RSpec.describe Queries::ItemsQuery, type: :graphql do
  subject(:resolver) { described_class.new(object: nil, context: query_context, field: nil) }

  describe "#resolve" do
    let!(:item_2) { FactoryBot.create(:item, uid: "2", name: "두 번째 아이템") }
    let!(:item_1) { FactoryBot.create(:item, uid: "1", name: "첫 번째 아이템") }

    it "returns all items when uids is omitted" do
      expect(resolver.resolve.pluck(:uid)).to eq(%w[1 2])
    end

    it "returns matching items when uids is present" do
      expect(resolver.resolve(uids: ["2"]).pluck(:uid)).to eq(["2"])
    end

    it "returns no items when uids is explicitly empty" do
      expect(resolver.resolve(uids: [])).to be_empty
    end
  end

  describe "GraphQL execution" do
    before do
      FactoryBot.create(:item, uid: "1", name: "첫 번째 아이템")
      FactoryBot.create(:item, uid: "2", name: "두 번째 아이템")
      FactoryBot.create(:item, uid: "3", name: "세 번째 아이템")
    end

    it "returns all items when uids is omitted" do
      result = execute_graphql(<<~GRAPHQL)
        query {
          items {
            uid
            name
            rarity
            category
            subCategory
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "items").map { |item| item["uid"] }).to eq(%w[1 2 3])
    end

    it "batch loads item names" do
      translation_queries = []

      callback = lambda do |_name, _started, _finished, _id, payload|
        translation_queries << payload[:sql] if payload[:sql].include?('FROM "translations"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        execute_graphql(<<~GRAPHQL)
          query {
            items {
              uid
              name
            }
          }
        GRAPHQL
      end

      expect(translation_queries.size).to eq(1)
    end
  end
end
