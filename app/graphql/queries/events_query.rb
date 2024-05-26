module Queries
  class EventsQuery < Queries::BaseQuery
    type Types::EventType.connection_type, null: false

    argument :until_after, GraphQL::Types::ISO8601DateTime, required: false

    def resolve(until_after: nil)
      results = Event.order(since: :asc, until: :asc)
      results = results.where("until >= ?", until_after) if until_after.present?
      results
    end
  end
end
