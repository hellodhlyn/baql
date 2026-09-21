require "rails_helper"

RSpec.describe Queries::FurnitureGroupsQuery, type: :graphql do
  subject(:resolver) { described_class.new(object: nil, context: query_context, field: nil) }

  describe "#resolve" do
    let!(:group_2) { FactoryBot.create(:furniture_group, uid: "101") }
    let!(:group_1) { FactoryBot.create(:furniture_group, uid: "100") }

    it "returns all furniture groups when uids is omitted" do
      expect(resolver.resolve.pluck(:uid)).to eq(%w[100 101])
    end

    it "returns matching furniture groups when uids is present" do
      expect(resolver.resolve(uids: ["101"]).pluck(:uid)).to eq(["101"])
    end

    it "returns no furniture groups when uids is explicitly empty" do
      expect(resolver.resolve(uids: [])).to be_empty
    end
  end

  describe "GraphQL execution" do
    before do
      group = FactoryBot.create(:furniture_group, uid: "100", name: "모모프렌즈 카페 세트")
      group.set_description("카페 세트 설명", "ko")
      group.set_name("Momo Friends Cafe Set", "en")
      group.set_description("Momo Friends Cafe Set description", "en")
      FactoryBot.create(:furniture, uid: "300")
      FactoryBot.create(:furniture, uid: "301", furniture_group_uid: group.uid)
      FactoryBot.create(:furniture, uid: "299", furniture_group_uid: group.uid, name: "의자")
    end

    it "returns furniture groups with their furnitures" do
      result = execute_graphql(<<~GRAPHQL)
        query {
          furnitureGroups {
            uid
            name
            furnitures {
              uid
              furnitureGroup { uid }
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      groups = result.dig("data", "furnitureGroups")
      expect(groups.map { |group| group["uid"] }).to eq(%w[100])
      expect(groups.first["name"]).to eq("모모프렌즈 카페 세트")
      expect(groups.first["furnitures"].map { |furniture| furniture["uid"] }).to eq(%w[299 301])
      expect(groups.first["furnitures"].map { |furniture| furniture.dig("furnitureGroup", "uid") })
        .to eq(%w[100 100])
    end

    it "returns names and descriptions in the requested language with fallback" do
      result = execute_graphql(<<~GRAPHQL)
        query {
          furnitureGroups(uids: ["100"]) {
            name
            englishName: name(lang: en)
            description
            englishDescription: description(lang: en)
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "furnitureGroups", 0)).to eq(
        "name" => "모모프렌즈 카페 세트",
        "englishName" => "Momo Friends Cafe Set",
        "description" => "카페 세트 설명",
        "englishDescription" => "Momo Friends Cafe Set description",
      )
    end

    it "batch loads group names" do
      translation_queries = []

      callback = lambda do |_name, _started, _finished, _id, payload|
        translation_queries << payload[:sql] if payload[:sql].include?('FROM "translations"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        execute_graphql(<<~GRAPHQL)
          query {
            furnitureGroups {
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
