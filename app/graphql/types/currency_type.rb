module Types
  class CurrencyType < Types::Base::Object
    implements Types::ResourceInterface

    field :uid, String, null: false
    field :name, String, null: false
    field :rarity, Int, null: false
  end
end
