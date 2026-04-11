module Types
  # DEPRECATED: Use Types::ResourceInterface and the individual types
  # (Types::ItemType, Types::CurrencyType, Types::EquipmentType, Types::FurnitureType) instead.
  class ResourceType < Types::Base::Object
    field :type, Types::Enums::ResourceTypeEnum, null: false
    def type = object.resource_type

    field :uid, String, null: false
    field :name, String, null: false
    field :category, String, null: false
    field :sub_category, String, null: true
    field :rarity, Int, null: false
  end
end
