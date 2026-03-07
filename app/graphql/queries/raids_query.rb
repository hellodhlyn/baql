module Queries
  class RaidsQuery < Queries::BaseQuery
    type Types::RaidType.connection_type, null: false

    argument :until_after,  GraphQL::Types::ISO8601DateTime, required: false # deprecated: use endAfter
    argument :since_before, GraphQL::Types::ISO8601DateTime, required: false # deprecated: use startBefore
    argument :end_after,    GraphQL::Types::ISO8601DateTime, required: false
    argument :start_before, GraphQL::Types::ISO8601DateTime, required: false
    argument :uids,  [String],                        required: false
    argument :types, [Types::RaidType::RaidTypeEnum], required: false

    def resolve(until_after: nil, since_before: nil, end_after: nil, start_before: nil, uids: nil, types: nil)
      results = Raid.order(since: :asc, until: :asc)
      effective_end_after    = end_after    || until_after
      effective_start_before = start_before || since_before
      results = results.where("until >= ?", effective_end_after)    if effective_end_after.present?
      results = results.where("since < ?",  effective_start_before) if effective_start_before.present?
      results = results.where(uid: uids)  if uids.present?
      results = results.where(type: types) if types.present?
      results
    end
  end
end
