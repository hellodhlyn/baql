module Queries
  class RaidsQuery < Queries::BaseQuery
    type Types::RaidType.connection_type, null: false

    argument :end_after,    GraphQL::Types::ISO8601DateTime, required: false
    argument :start_before, GraphQL::Types::ISO8601DateTime, required: false
    argument :uids,  [String],                        required: false
    argument :types, [Types::RaidType::RaidTypeEnum], required: false

    def resolve(end_after: nil, start_before: nil, uids: nil, types: nil)
      results = Raid.order(since: :asc, until: :asc)
      results = results.where("until >= ?", end_after)    if end_after.present?
      results = results.where("since < ?",  start_before) if start_before.present?
      results = results.where(uid: uids)  if uids.present?
      results = results.where(type: types) if types.present?
      results
    end
  end
end
