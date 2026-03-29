# frozen_string_literal: true

module Mutations
  module EventContents
    class CreateEventContent < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :raw_data_first, GraphQL::Types::JSON, required: false
      argument :raw_data_rerun, GraphQL::Types::JSON, required: false

      field :event_content, Types::EventContentType, null: true

      def resolve(uid:, **attrs)
        [:raw_data_first, :raw_data_rerun].each do |key|
          val = attrs[key]
          next if val.nil?
          raise GraphQL::ExecutionError, "#{key} must be a JSON object" unless val.is_a?(Hash)
        end

        event_content = EventContent.new(
          **attrs.compact,
          uid: uid,
          baql_id: "#{EventContent::BAQL_ID_PREFIX}#{uid}",
        )
        save_record(event_content, event_content: event_content)
      end
    end
  end
end
