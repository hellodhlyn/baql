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

    field :rank_visible, Boolean, null: false
    field :ranks, [Types::RaidRankType], null: false do
      argument :rank_after, Integer, required: false
      argument :rank_before, Integer, required: false
      argument :first, Integer, required: false, default_value: 20
      argument :filter, [Types::RaidRankType::RaidRankFilterType], required: false, deprecation_reason: "Use include_students and exclude_students instead"
      argument :include_students, [Types::RaidRankType::RaidRankFilterType], required: false
      argument :exclude_students, [Types::RaidRankType::RaidRankFilterType], required: false
    end

    def ranks(rank_after: nil, rank_before: nil, first: 20, filter: nil, include_students: nil, exclude_students: nil)
      ranks = object.ranks(
        rank_after: rank_after,
        rank_before: rank_before,
        first: first,
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
  end
end
