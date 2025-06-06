module Queries
  class RaidsQuery < Queries::BaseQuery
    type Types::RaidType.connection_type, null: false

    argument :until_after,  GraphQL::Types::ISO8601DateTime, required: false
    argument :since_before, GraphQL::Types::ISO8601DateTime, required: false
    argument :uids, [String], required: false
    argument :types, [Types::RaidType::RaidTypeEnum], required: false

    def resolve(until_after: nil, since_before: nil, uids: nil, types: nil)
      results = Raid.order(since: :asc, until: :asc)
      results = results.where("until >= ?", until_after) if until_after.present?
      results = results.where("since < ?", since_before) if since_before.present?
      results = results.where(uid: uids) if uids.present?
      results = results.where(type: types) if types.present?
      results
    end
  end
end
