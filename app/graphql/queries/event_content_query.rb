module Queries
  class EventContentQuery < Queries::BaseQuery
    type Types::EventContentType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      EventContent.find_by(uid: uid)
    end
  end
end
