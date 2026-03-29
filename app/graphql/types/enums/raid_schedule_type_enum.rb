# frozen_string_literal: true

module Types
  module Enums
    class RaidScheduleTypeEnum < Types::Base::Enum
      RaidSchedule::RAID_TYPES.each { |t| value t, value: t }
    end
  end
end
