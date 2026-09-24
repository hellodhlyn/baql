# frozen_string_literal: true

module Types
  class FurnitureTemplatePreviewType < Types::Base::Object
    graphql_name "FurnitureTemplatePreview"

    field :uid, String, null: false
    field :title, String, null: false do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :image_url, String, null: false
    field :thumbnail_url, String, null: false

    def title(lang: Constants::DEFAULT_LANGUAGE)
      dataloader
        .with(Sources::TranslationByKey, lang, fallback_language: Constants::DEFAULT_LANGUAGE)
        .load("#{object.translation_key_prefix}::name")
    end

    def image_url
      asset_url(object.image_asset_key)
    end

    def thumbnail_url
      asset_url(object.thumbnail_asset_key)
    end

    private

    def asset_url(key)
      raise GraphQL::ExecutionError, "Furniture preview asset is not ready" if key.blank?

      base_url = ENV["ASSET_BASE_URL"].to_s
      raise GraphQL::ExecutionError, "ASSET_BASE_URL is not configured" if base_url.blank?

      "#{base_url.chomp("/")}/#{key.sub(%r{\A/+}, "")}"
    end
  end
end
