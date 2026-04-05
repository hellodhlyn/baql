module Types
  class GearGrowthItemType < Types::Base::Object
    field :item, Types::ItemType, null: false
    field :gear_tier, Int, null: false
    field :amount, Int, null: false
  end

  class GearType < Types::Base::Object
    field :name, String, null: false
    field :growth_items, [Types::GearGrowthItemType, null: false], null: false
  end
end
