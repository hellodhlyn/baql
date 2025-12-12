module Types
  module Enums
    class PositionType < Types::Base::Enum
      Student::SchaleDBMap::POSITIONS.values.each do |position|
        value position, value: position
      end
    end
  end
end
