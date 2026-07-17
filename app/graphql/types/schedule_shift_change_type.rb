# frozen_string_literal: true

module Types
  class ScheduleShiftChangeType < Types::Base::Object
    field :column, String, null: false
    field :before, GraphQL::Types::ISO8601DateTime, null: true
    field :after, GraphQL::Types::ISO8601DateTime, null: true
  end
end
