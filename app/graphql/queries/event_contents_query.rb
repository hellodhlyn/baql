module Queries
  class EventContentsQuery < Queries::BaseQuery
    type [Types::EventContentType], null: false

    argument :uids, [String], required: false

    def resolve(uids: nil)
      scope = EventContent.all
      scope = scope.where(uid: uids) if uids.present?
      scope
    end
  end
end
