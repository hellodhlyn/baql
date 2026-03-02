module Types
  module ResourceInterface
    include Types::Base::Interface

    class ResourceTypeEnum < Types::Base::Enum
      value "item", value: "item"
      value "currency", value: "currency"
      value "equipment", value: "equipment"
      value "furniture", value: "furniture"
    end

    field :type, ResourceTypeEnum, null: false
    def type
      case object
      when ::Item,      ::Resources::Item      then "item"
      when ::Currency,  ::Resources::Currency  then "currency"
      when ::Equipment, ::Resources::Equipment then "equipment"
      when ::Furniture, ::Resources::Furniture then "furniture"
      else raise "Unexpected object: #{object}"
      end
    end

    field :uid, String, null: false
    field :name, String, null: false
    field :rarity, Int, null: false

    definition_methods do
      def resolve_type(object, context)
        case object
        when ::Item,      ::Resources::Item      then Types::ItemType
        when ::Currency,  ::Resources::Currency  then Types::CurrencyType
        when ::Equipment, ::Resources::Equipment then Types::EquipmentType
        when ::Furniture, ::Resources::Furniture then Types::FurnitureType
        else raise "Unexpected object: #{object}"
        end
      end
    end
  end
end
