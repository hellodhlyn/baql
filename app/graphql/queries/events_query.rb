module Queries
  class EventsQuery < Queries::BaseQuery
    type Types::EventType.connection_type, null: false

    argument :until_after,  GraphQL::Types::ISO8601DateTime, required: false
    argument :since_before, GraphQL::Types::ISO8601DateTime, required: false

    argument :uids, [String], required: false

    def resolve(until_after: nil, since_before: nil, uids: nil)
      results = Event.includes(:pickups, pickups: :student).order(since: :asc, until: :asc)
      results = results.where("until >= ?", until_after) if until_after.present?
      results = results.where("since < ?", since_before) if since_before.present?
      results = results.where(uid: uids) if uids.present?
      results
    end
  end
end
