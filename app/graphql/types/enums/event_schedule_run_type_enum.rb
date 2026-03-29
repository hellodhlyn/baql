# frozen_string_literal: true

module Types
  module Enums
    class EventScheduleRunTypeEnum < Types::Base::Enum
      Constants::EVENT_SCHEDULE_RUN_TYPES.each { |t| value t, value: t }
    end
  end
end
