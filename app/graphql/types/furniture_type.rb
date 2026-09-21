module Types
  class FurnitureType < Types::Base::Object
    implements Types::ResourceInterface

    field :uid, String, null: false
    field :rarity, Int, null: false
    field :category, String, null: false
    field :sub_category, String, null: true
    field :tags, [String], null: false
    field :furniture_group, Types::FurnitureGroupType, null: true

    def furniture_group
      return nil if object.furniture_group_uid.nil?

      dataloader
        .with(Sources::RecordByUid, ::FurnitureGroup)
        .load(object.furniture_group_uid)
    end
  end
end
