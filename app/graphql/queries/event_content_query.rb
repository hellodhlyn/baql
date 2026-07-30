module Queries
  class EventContentQuery < Queries::BaseQuery
    type Types::EventContentType, null: true

    argument :uid, String, required: true
    def resolve(uid:)
      EventContent
        .select(:uid, :baql_id)
        .find_by(uid: uid)
    end
  end
end
