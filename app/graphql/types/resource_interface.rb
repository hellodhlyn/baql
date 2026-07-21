module Types
  module ResourceInterface
    include Types::Base::Interface

    field :type, Types::Enums::ResourceTypeEnum, null: false
    def type
      case object
      when ::Item      then "item"
      when ::Currency  then "currency"
      when ::Equipment then "equipment"
      when ::Furniture then "furniture"
      else raise "Unexpected object: #{object}"
      end
    end

    field :uid, String, null: false
    field :name, String, null: false do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :description, String, null: true do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :rarity, Int, null: false

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

    definition_methods do
      def resolve_type(object, context)
        case object
        when ::Item      then Types::ItemType
        when ::Currency  then Types::CurrencyType
        when ::Equipment then Types::EquipmentType
        when ::Furniture then Types::FurnitureType
        else raise "Unexpected object: #{object}"
        end
      end
    end
  end
end
