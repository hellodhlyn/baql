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
      item = FactoryBot.create(:item, uid: "1", name: "첫 번째 아이템")
      item.set_name("First item", "en")
      item.set_description("첫 번째 아이템 설명", "ko")
      item.set_description("First item description", "en")
      item_without_english_translation = FactoryBot.create(:item, uid: "2", name: "두 번째 아이템")
      item_without_english_translation.set_description("두 번째 아이템 설명", "ko")
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

    it "returns item names and descriptions in the requested language" do
      result = execute_graphql(<<~GRAPHQL)
        query {
          items(uids: ["1"]) {
            name
            englishName: name(lang: en)
            description
            englishDescription: description(lang: en)
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "items", 0)).to eq(
        "name" => "첫 번째 아이템",
        "englishName" => "First item",
        "description" => "첫 번째 아이템 설명",
        "englishDescription" => "First item description",
      )
    end

    it "falls back to Korean when the requested translations are missing" do
      result = execute_graphql(<<~GRAPHQL)
        query {
          items(uids: ["2"]) {
            name(lang: en)
            description(lang: en)
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "items", 0)).to eq(
        "name" => "두 번째 아이템",
        "description" => "두 번째 아이템 설명",
      )
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
