module Queries
  class RaidScheduleBySeasonIndexQuery < Queries::BaseQuery
    type Types::RaidScheduleType, null: true

    argument :region, String, required: true
    argument :season_index, Integer, required: true

    PREFERRED_RAID_TYPE_ORDER = %w[total_assault elimination allied unlimit].freeze

    def resolve(region:, season_index:)
      # region + season_index is not unique in the DB, so keep the fallback deterministic.
      RaidSchedule.where(region: region, season_index: season_index)
        .in_order_of(:raid_type, PREFERRED_RAID_TYPE_ORDER)
        .first
    end
  end
end
