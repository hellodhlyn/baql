# frozen_string_literal: true

module Types
  class FurnitureThemeType < Types::Base::Object
    graphql_name "FurnitureTheme"

    field :uid, String, null: false
    field :name, String, null: false do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :description, String, null: true do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :furnitures, [Types::FurnitureType], null: false
    field :previews, [Types::FurnitureTemplatePreviewType], null: false

    def name(lang: Constants::DEFAULT_LANGUAGE)
      translation("#{object.translation_key_prefix}::name", lang)
    end

    def description(lang: Constants::DEFAULT_LANGUAGE)
      translation("#{object.translation_key_prefix}::description", lang)
    end

    def furnitures
      dataloader.with(Sources::FurnituresByThemeUid).load(object.uid)
    end

    def previews
      dataloader.with(Sources::RecordsByForeignKey, FurnitureTemplatePreview, :furniture_theme_uid, order: :display_order)
        .load(object.uid)
    end

    private

    def translation(key, language)
      dataloader
        .with(Sources::TranslationByKey, language, fallback_language: Constants::DEFAULT_LANGUAGE)
        .load(key)
    end
  end
end
