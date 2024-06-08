module Queries
  class EventQuery < Queries::BaseQuery
    type Types::EventType, null: true

    argument :event_id, String, required: true

    def resolve(event_id:)
      Event.find_by(event_id: event_id)
    end
  end
end
