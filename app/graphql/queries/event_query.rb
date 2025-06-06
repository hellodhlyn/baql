module Queries
  class EventQuery < Queries::BaseQuery
    type Types::EventType, null: true

    argument :uid, String, required: true

    def resolve(uid: nil)
      Event.find_by(uid: uid)
    end
  end
end
