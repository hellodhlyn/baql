module Queries
  class RaidQuery < Queries::BaseQuery
    type Types::RaidType, null: true

    argument :raid_id, String, required: true

    def resolve(raid_id:)
      Raid.find_by(raid_id: raid_id)
    end
  end
end
