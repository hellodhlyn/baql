# frozen_string_literal: true

module Types
  class ScheduleShiftUpdateType < Types::Base::Object
    field :schedule_type, String, null: false
    field :identifier, String, null: false
    field :changes, [Types::ScheduleShiftChangeType], null: false
  end
end
