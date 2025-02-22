module Types
  class RaidType < Types::Base::Object
    implements GraphQL::Types::Relay::Node
    implements Types::ContentInterface

    class RaidTypeEnum < Types::Base::Enum
      Raid::RAID_TYPES.each do |type|
        value type, value: type
      end
    end

    class TerrainEnum < Types::Base::Enum
      Raid::TERRAINS.each do |type|
        value type, value: type
      end
    end

    field :raid_id, String, null: false
    field :type, RaidTypeEnum, null: false
    field :name, String, null: false
    field :boss, String, null: false
    field :terrain, TerrainEnum, null: false
    field :attack_type, Types::Enums::AttackType, null: false
    field :defense_type, Types::Enums::DefenseType, null: false
  end
end
