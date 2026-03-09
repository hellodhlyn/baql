module Types
  class ItemType < Types::Base::Object
    implements Types::ResourceInterface

    field :uid, String, null: false
    field :name, String, null: false
    field :rarity, Int, null: false
    field :category, String, null: false
    field :sub_category, String, null: true
  end
end
