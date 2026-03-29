# frozen_string_literal: true

module Types
  class EventContentScheduleType < Types::Base::Object
    field :region,   String, null: false
    field :run_type, String, null: false
    field :start_at, GraphQL::Types::ISO8601DateTime, null: false
    field :end_at,   GraphQL::Types::ISO8601DateTime, null: true
  end
end
