# frozen_string_literal: true

module Types
  module Inputs
    class MiniStoryScheduleInput < Types::Base::InputObject
      argument :region,      Types::Enums::RegionType,        required: true
      argument :released_at, GraphQL::Types::ISO8601DateTime, required: true
    end
  end
end
