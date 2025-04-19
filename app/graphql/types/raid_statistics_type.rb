module Types
  class RaidStatisticsType < Types::Base::Object
    implements GraphQL::Types::Relay::Node

    class TierAndCountType < Types::Base::Object
      field :tier, Int, null: false
      field :count, Int, null: false
    end

    field :student, Types::StudentType, null: false
    field :raid, Types::RaidType, null: false
    field :defense_type, Types::Enums::DefenseType, null: false
    field :difficulty, Types::Enums::DifficultyType, null: false
    field :slots_count, Int, null: false
    field :slots_by_tier, [TierAndCountType], null: false
    field :assists_count, Int, null: false
    field :assists_by_tier, [TierAndCountType], null: false

    def slots_by_tier
      object.slots_by_tier.map { |tier, count| { tier: tier.to_i, count: count } }
    end

    def assists_by_tier
      object.assists_by_tier.map { |tier, count| { tier: tier.to_i, count: count } }
    end
  end
end
