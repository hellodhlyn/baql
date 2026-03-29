# frozen_string_literal: true

module Types
  module Enums
    class RegionType < Types::Base::Enum
      Constants::REGIONS.each { |r| value r, value: r }
    end
  end
end
