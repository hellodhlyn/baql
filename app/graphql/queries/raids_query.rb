module Queries
  class RaidsQuery < Queries::BaseQuery
    type Types::RaidType.connection_type, null: false

    argument :until_after, GraphQL::Types::ISO8601DateTime, required: false
    argument :raid_ids, [String], required: false

    def resolve(until_after: nil, raid_ids: nil)
      results = Raid.order(since: :asc, until: :asc)
      results = results.where("until >= ?", until_after) if until_after.present?
      results = results.where(raid_id: raid_ids) if raid_ids.present?
      results
    end
  end
end
