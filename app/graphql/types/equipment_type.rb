module Types
  class EquipmentType < Types::Base::Object
    implements Types::ResourceInterface

    field :uid, String, null: false
    field :name, String, null: false
    field :rarity, Int, null: false
    field :category, String, null: false
    field :sub_category, String, null: true

    def name
      dataloader
        .with(Sources::TranslationByKey, Constants::DEFAULT_LANGUAGE)
        .load("#{object.translation_key_prefix}::name")
    end
  end
end
