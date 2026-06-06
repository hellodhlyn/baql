module Types
  class RaidScheduleType < Types::Base::Object
    field :uid, String, null: false
    field :raid_boss, Types::RaidBossType, null: false
    field :region, String, null: false
    field :raid_type, String, null: false
    field :season_index, Integer, null: false
    field :terrain, Types::Enums::TerrainType, null: false
    field :start_at, GraphQL::Types::ISO8601DateTime, null: true
    field :end_at, GraphQL::Types::ISO8601DateTime, null: true
    field :attack_type, Types::Enums::AttackType, null: true
    field :defense_type_sets, [Types::DefenseTypeSetType], null: false
    field :defense_types, [Types::DefenseTypeAndDifficultyType], null: false,
      deprecation_reason: "Use `defense_type_sets` instead"
    field :jp_schedule, Types::RaidScheduleType, null: true
  end
end
