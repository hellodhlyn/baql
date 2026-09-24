module Types
  class FurnitureType < Types::Base::Object
    implements Types::ResourceInterface

    field :uid, String, null: false
    field :rarity, Int, null: false
    field :category, String, null: false
    field :sub_category, String, null: true
    field :tags, [String], null: false
    field :theme, Types::FurnitureThemeType, null: true
    field :image_url, String, null: false

    def theme
      return nil if object.theme_uid.blank?

      dataloader.with(Sources::RecordByUid, FurnitureTheme).load(object.theme_uid)
    end

    def image_url
      raise GraphQL::ExecutionError, "Furniture icon asset is not ready" if object.image_asset_key.blank?

      base_url = ENV["ASSET_BASE_URL"].to_s
      raise GraphQL::ExecutionError, "ASSET_BASE_URL is not configured" if base_url.blank?

      "#{base_url.chomp("/")}/#{object.image_asset_key.sub(%r{\A/+}, "")}"
    end
  end
end
