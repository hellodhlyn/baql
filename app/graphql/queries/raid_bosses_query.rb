module Queries
  class RaidBossesQuery < Queries::BaseQuery
    type Types::RaidBossType.connection_type, null: false

    argument :raid_type, String, required: false

    def resolve(raid_type: nil)
      results = RaidBoss.all
      results = results.where(raid_type: raid_type) if raid_type.present?
      results
    end
  end
end
