module Types
  class ItemType < Types::Base::Object
    field :uid, String, null: false
    field :name, String, null: false
    field :category, String, null: false
    field :sub_category, String, null: true
    field :rarity, Int, null: false
  end
end
