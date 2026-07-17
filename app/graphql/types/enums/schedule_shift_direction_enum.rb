# frozen_string_literal: true

module Types
  module Enums
    class ScheduleShiftDirectionEnum < Types::Base::Enum
      value "advance", value: "advance", description: "Move schedules earlier"
      value "postpone", value: "postpone", description: "Move schedules later"
    end
  end
end
