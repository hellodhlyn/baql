module Types
  class FurnitureGroupType < Types::Base::Object
    field :uid, String, null: false
    field :name, String, null: false do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :description, String, null: true do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :furnitures, [Types::FurnitureType], null: false

    def name(lang: Constants::DEFAULT_LANGUAGE)
      dataloader
        .with(Sources::TranslationByKey, lang, fallback_language: Constants::DEFAULT_LANGUAGE)
        .load("#{object.translation_key_prefix}::name")
    end

    def description(lang: Constants::DEFAULT_LANGUAGE)
      dataloader
        .with(Sources::TranslationByKey, lang, fallback_language: Constants::DEFAULT_LANGUAGE)
        .load("#{object.translation_key_prefix}::description")
    end

    def furnitures
      dataloader
        .with(Sources::RecordsByForeignKey, ::Furniture, :furniture_group_uid, order: :uid)
        .load(object.uid)
    end
  end
end
