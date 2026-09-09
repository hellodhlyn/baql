module Types
  class EmblemType < Types::Base::Object
    implements Types::ResourceInterface

    field :uid, String, null: false
    field :rarity, Int, null: false
    field :category, String, null: false
    field :image_url, String, null: true do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end

    def image_url(lang: Constants::DEFAULT_LANGUAGE)
      key = object.image_asset_keys[lang] ||
        object.image_asset_keys[Constants::DEFAULT_LANGUAGE] ||
        object.image_asset_keys["ja"]
      return nil if key.blank?

      base_url = ENV["ASSET_BASE_URL"].to_s
      raise GraphQL::ExecutionError, "ASSET_BASE_URL is not configured" if base_url.blank?

      "#{base_url.chomp("/")}/#{key.sub(%r{\A/+}, "")}"
    end
  end
end
