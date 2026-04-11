module Types
  module Enums
    class ResourceTypeEnum < Types::Base::Enum
      value "item", value: "item"
      value "currency", value: "currency"
      value "equipment", value: "equipment"
      value "furniture", value: "furniture"
    end
  end
end
