module Queries
  class MiniEventContentQuery < Queries::BaseQuery
    type Types::MiniEventContentType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      MiniEventContent.find_by(uid: uid)
    end
  end
end
