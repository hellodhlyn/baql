module Types
  class ItemEventBonusType < Types::Base::Object
    field :student, StudentType, null: false
    field :ratio, Float, null: false
  end

  class ItemType < Types::Base::Object
    field :item_id, String, null: false
    field :name, String, null: false
    field :image_id, String, null: false
    field :event_bonuses, [ItemEventBonusType], null: false
  end
end
