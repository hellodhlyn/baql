module Queries
  class EventQuery < Queries::BaseQuery
    type Types::EventType, null: true

    # [DEPRECATED v1] Use `uid` instead
    argument :event_id, String, required: false
    argument :uid, String, required: false

    def resolve(event_id: nil, uid: nil)
      event_uid = event_id || uid
      raise GraphQL::ExecutionError, "Either event_id or uid must be provided" if event_uid.blank?

      Event.find_by(uid: event_uid)
    end
  end
end
