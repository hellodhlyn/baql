module Queries
  class EventQuery < Queries::BaseQuery
    type Types::EventType, null: true

    argument :uid, String, required: true

    def resolve(uid: nil)
      Event.includes(:pickups, pickups: :student).find_by(uid: uid)
    end
  end
end
