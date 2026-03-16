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
      when ::Item      then "item"
      when ::Currency  then "currency"
      when ::Equipment then "equipment"
      when ::Furniture then "furniture"
      else raise "Unexpected object: #{object}"
      end
    end

    field :uid, String, null: false
    field :name, String, null: false
    field :rarity, Int, null: false

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
