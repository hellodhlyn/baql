module Types
  class ResourceType < Types::Base::Object
    class ResourceTypeEnum < Types::Base::Enum
      value "item", value: "item"
      value "equipment", value: "equipment"
      value "furniture", value: "furniture"
      value "currency", value: "currency"
    end

    field :type, ResourceTypeEnum, null: false
    def type = object.resource_type

    field :uid, String, null: false
    field :name, String, null: false
    field :category, String, null: false
    field :sub_category, String, null: true
    field :rarity, Int, null: false
  end
end
