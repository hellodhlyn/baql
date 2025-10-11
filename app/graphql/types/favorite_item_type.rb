module Types
  class FavoriteItemType < Types::Base::Object
    field :student, "Types::StudentType", null: false
    field :item, "Types::ItemType", null: false
    field :exp, Int, null: false
    field :favorite_level, Int, null: false
    field :favorited, Boolean, null: false
  end
end
