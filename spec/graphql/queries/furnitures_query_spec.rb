require "rails_helper"

RSpec.describe Queries::FurnituresQuery, type: :graphql do
  def ready_catalog!(furniture_count:, theme_count: 0, preview_count: 0, assets_ready: true)
    FurnitureCatalogState.create!(
      id: FurnitureCatalogState::SINGLETON_ID,
      data_ready: true,
      assets_ready: assets_ready,
      furniture_count: furniture_count,
      theme_count: theme_count,
      preview_count: preview_count,
      database_sha256: "a" * 64,
    )
  end

  around do |example|
    previous_asset_base_url = ENV["ASSET_BASE_URL"]
    ENV["ASSET_BASE_URL"] = "https://assets.example/"
    example.run
  ensure
    ENV["ASSET_BASE_URL"] = previous_asset_base_url
  end

  describe "GraphQL execution" do
    it "returns a not-ready error instead of an empty catalog before both imports finish" do
      FurnitureCatalogState.create!(
        id: FurnitureCatalogState::SINGLETON_ID,
        data_ready: true,
        assets_ready: false,
        furniture_count: 0,
        theme_count: 0,
        preview_count: 0,
      )

      result = execute_graphql("{ furnitures { uid } }")

      expect(result.dig("errors", 0, "message")).to eq("Furniture catalog is not ready")
      expect(result.dig("data", "furnitures")).to be_nil
    end

    it "returns an explicit empty list for a ready empty catalog" do
      ready_catalog!(furniture_count: 0)

      result = execute_graphql("{ furnitures { uid } }")

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "furnitures")).to eq([])
    end

    it "distinguishes omitted, empty, and unknown UID filters and excludes legacy rows" do
      theme = FurnitureTheme.create!(uid: "105", baql_id: "baql::furniture_themes::105")
      theme.set_name("Cafe theme", "ko")
      first = FactoryBot.create(:furniture, uid: "1", in_catalog: true, theme_uid: theme.uid, image_asset_key: "images/resources/furnitures/1.webp", name: "첫 번째")
      second = FactoryBot.create(:furniture, uid: "2", in_catalog: true, image_asset_key: "images/resources/furnitures/2.webp", name: "두 번째")
      FactoryBot.create(:furniture, uid: "legacy", in_catalog: false, image_asset_key: "images/legacy.webp", name: "기존 가구")
      ready_catalog!(furniture_count: 2, theme_count: 1)

      all = execute_graphql("{ furnitures { uid theme { uid name } imageUrl } }")
      empty = execute_graphql("{ furnitures(uids: []) { uid } }")
      missing = execute_graphql('{ furnitures(uids: ["unknown"]) { uid } }')

      expect(all["errors"]).to be_nil
      expect(all.dig("data", "furnitures")).to eq([
        { "uid" => first.uid, "theme" => { "uid" => theme.uid, "name" => "Cafe theme" }, "imageUrl" => "https://assets.example/images/resources/furnitures/1.webp" },
        { "uid" => second.uid, "theme" => nil, "imageUrl" => "https://assets.example/images/resources/furnitures/2.webp" },
      ])
      expect(empty.dig("data", "furnitures")).to eq([])
      expect(missing.dig("data", "furnitures")).to eq([])
    end

    it "exposes all theme members and their mapped template previews" do
      theme = FurnitureTheme.create!(uid: "105", baql_id: "baql::furniture_themes::105")
      theme.set_name("온천 테마", "ko")
      theme.set_description("테마 설명", "ko")
      member = FactoryBot.create(:furniture, uid: "1", in_catalog: true, theme_uid: theme.uid, image_asset_key: "images/resources/furnitures/1.webp", name: "가구")
      FactoryBot.create(:furniture, uid: "2", in_catalog: true, theme_uid: theme.uid, image_asset_key: "images/resources/furnitures/2.webp", name: "두 번째 가구")
      preview = FurnitureTemplatePreview.create!(
        uid: "6",
        baql_id: "baql::furniture_template_previews::6",
        furniture_theme_uid: theme.uid,
        display_order: 0,
        image_asset_key: "images/resources/furniture_templates/6/image.webp",
        thumbnail_asset_key: "images/resources/furniture_templates/6/thumbnail.webp",
      )
      preview.set_name("온천 미리보기", "ko")
      ready_catalog!(furniture_count: 2, theme_count: 1, preview_count: 1)

      result = execute_graphql(<<~GRAPHQL)
        query {
          furnitureTheme(uid: "105") {
            uid
            name
            description
            furnitures { uid }
            previews { uid title imageUrl thumbnailUrl }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "furnitureTheme")).to eq(
        "uid" => "105",
        "name" => "온천 테마",
        "description" => "테마 설명",
        "furnitures" => [{ "uid" => member.uid }, { "uid" => "2" }],
        "previews" => [{
          "uid" => preview.uid,
          "title" => "온천 미리보기",
          "imageUrl" => "https://assets.example/images/resources/furniture_templates/6/image.webp",
          "thumbnailUrl" => "https://assets.example/images/resources/furniture_templates/6/thumbnail.webp",
        }],
      )
    end

    it "returns null for an unknown theme UID" do
      ready_catalog!(furniture_count: 0)

      result = execute_graphql('{ furnitureTheme(uid: "missing") { uid } }')

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "furnitureTheme")).to be_nil
    end

    it "keeps theme, member, preview, and translation SQL constant across a growing root list" do
      theme = FurnitureTheme.create!(uid: "105", baql_id: "baql::furniture_themes::105")
      theme.set_name("테마 105", "ko")
      FactoryBot.create(:furniture, uid: "1", in_catalog: true, theme_uid: theme.uid, name: "첫 번째")
      preview = FurnitureTemplatePreview.create!(
        uid: "6",
        baql_id: "baql::furniture_template_previews::6",
        furniture_theme_uid: theme.uid,
        display_order: 0,
        image_asset_key: "images/resources/furniture_templates/6/image.webp",
        thumbnail_asset_key: "images/resources/furniture_templates/6/thumbnail.webp",
      )
      preview.set_name("미리보기 6", "ko")
      ready_catalog!(furniture_count: 1, theme_count: 1, preview_count: 1)
      query = "{ furnitureThemes { uid name furnitures { uid name theme { uid } } previews { uid title } } }"

      fetch_catalog = lambda do
        result, queries = capture_sql { execute_graphql(query) }
        expect(result["errors"]).to be_nil
        [
          result.dig("data", "furnitureThemes"),
          [
            queries.count { |entry| entry.fetch(:sql).include?('FROM "furniture_themes"') },
            queries.count { |entry| entry.fetch(:sql).include?('FROM "furnitures"') },
            queries.count { |entry| entry.fetch(:sql).include?('FROM "furniture_template_previews"') },
            queries.count { |entry| entry.fetch(:sql).include?('FROM "translations"') },
          ],
        ]
      end

      baseline_rows, baseline_counts = fetch_catalog.call
      19.times do |index|
        uid = (106 + index).to_s
        next_theme = FurnitureTheme.create!(uid: uid, baql_id: "baql::furniture_themes::#{uid}")
        next_theme.set_name("테마 #{uid}", "ko")
        FactoryBot.create(:furniture, uid: (index + 2).to_s, in_catalog: true, theme_uid: uid, name: "가구 #{uid}")
        next_preview_uid = (7 + index).to_s
        next_preview = FurnitureTemplatePreview.create!(
          uid: next_preview_uid,
          baql_id: "baql::furniture_template_previews::#{next_preview_uid}",
          furniture_theme_uid: uid,
          display_order: 0,
          image_asset_key: "images/resources/furniture_templates/#{next_preview_uid}/image.webp",
          thumbnail_asset_key: "images/resources/furniture_templates/#{next_preview_uid}/thumbnail.webp",
        )
        next_preview.set_name("미리보기 #{next_preview_uid}", "ko")
      end
      FurnitureCatalogState.current.update!(furniture_count: 20, theme_count: 20, preview_count: 20)

      expanded_rows, expanded_counts = fetch_catalog.call
      expect(expanded_counts).to eq(baseline_counts)
      expect(baseline_counts).to eq([2, 1, 1, 2])
      expect(expanded_rows.map { |row| row.fetch("uid") }).to eq(("105".."124").to_a)
      expanded_rows.each do |theme_row|
        expect(theme_row.fetch("name")).to be_present
        expect(theme_row.fetch("furnitures").size).to eq(1)
        member = theme_row.fetch("furnitures").first
        expect(member.fetch("name")).to be_present
        expect(member.dig("theme", "uid")).to eq(theme_row.fetch("uid"))
        expect(theme_row.fetch("previews").size).to eq(1)
        expect(theme_row.fetch("previews").first.fetch("title")).to be_present
      end
      expect(Furniture.where(in_catalog: true).count).to eq(20)
      expect(FurnitureTheme.count).to eq(20)
      expect(FurnitureTemplatePreview.count).to eq(20)
    end

    it "returns a not-ready error for theme queries before data and assets are ready" do
      result = execute_graphql('{ furnitureThemes { uid } furnitureTheme(uid: "105") { uid } }')

      expect(result.fetch("errors").map { |error| error.fetch("message") }).to eq(["Furniture catalog is not ready", "Furniture catalog is not ready"])
      expect(result.dig("data", "furnitureThemes")).to be_nil
      expect(result.dig("data", "furnitureTheme")).to be_nil
    end
  end
end
