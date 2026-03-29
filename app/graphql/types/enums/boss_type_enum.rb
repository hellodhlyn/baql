# frozen_string_literal: true

module Types
  module Enums
    class BossTypeEnum < Types::Base::Enum
      RaidBoss::RAID_TYPES.each { |t| value t, value: t }
    end
  end
end
