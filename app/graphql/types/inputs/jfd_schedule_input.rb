# frozen_string_literal: true

module Types
  module Inputs
    class JfdScheduleInput < Types::Base::InputObject
      argument :region,   Types::Enums::RegionType,        required: true
      argument :start_at, GraphQL::Types::ISO8601DateTime,  required: true
      argument :end_at,   GraphQL::Types::ISO8601DateTime,  required: false
    end
  end
end
