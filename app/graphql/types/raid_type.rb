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

    class DefenseTypeAndDifficulty < Types::Base::Object
      field :defense_type, Types::Enums::DefenseType, null: false
      field :difficulty, Types::Enums::DifficultyType, null: true
    end

    field :type, RaidTypeEnum, null: false
    field :name, String, null: false
    field :boss, String, null: false
    field :terrain, TerrainEnum, null: false
    field :attack_type, Types::Enums::AttackType, null: false
    field :defense_type, Types::Enums::DefenseType, null: false, deprecation_reason: "Use defense_types instead"
    field :defense_types, [DefenseTypeAndDifficulty], null: false

    field :rank_visible, Boolean, null: false
    field :ranks, [Types::RaidRankType], null: false do
      argument :defense_type, Types::Enums::DefenseType, required: false
      argument :rank_after, Integer, required: false
      argument :rank_before, Integer, required: false
      argument :first, Integer, required: false, default_value: 20
      argument :filter, [Types::RaidRankType::RaidRankFilterType], required: false, deprecation_reason: "Use include_students and exclude_students instead"
      argument :include_students, [Types::RaidRankType::RaidRankFilterType], required: false
      argument :exclude_students, [Types::RaidRankType::RaidRankFilterType], required: false
    end

    def ranks(defense_type: nil, rank_after: nil, rank_before: nil, first: 20, filter: nil, include_students: nil, exclude_students: nil)
      first_arg = first > 20 ? 20 : first
      ranks = object.ranks(
        defense_type: defense_type,
        rank_after: rank_after,
        rank_before: rank_before,
        first: first_arg,
        include_students: (filter || include_students)&.map(&:to_h),
        exclude_students: exclude_students&.map(&:to_h),
      )
      ranks.map do |row|
        {
          rank: row[:rank],
          score: row[:score],
          parties: row[:parties].each_with_index.map do |party, party_index|
            {
              party_index: party_index,
              slots: party,
            }
          end
        }
      end
    end

    field :statistics, [Types::RaidStatisticsType], null: false do
      argument :defense_type, Types::Enums::DefenseType, required: false
    end

    def statistics(defense_type: nil)
      query = RaidStatistics.where(raid: object)
      query = query.where(defense_type: defense_type) if defense_type.present?
      query.order(slots_count: :desc)
    end
  end
end
