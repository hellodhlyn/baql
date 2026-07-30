# frozen_string_literal: true

module Mutations
  module EventContents
    class CreateEventContent < Mutations::BaseMutation
      argument :uid, String, required: true

      field :event_content, Types::EventContentType, null: true

      def resolve(uid:)
        event_content = EventContent.new(
          uid: uid,
          baql_id: "#{EventContent::BAQL_ID_PREFIX}#{uid}",
        )
        save_record(event_content, event_content: event_content)
      end
    end
  end
end
