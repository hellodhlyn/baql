module Types
  module Enums
    class PositionType < Types::Base::Enum
      Student::POSITIONS.each do |position|
        value position, value: position
      end
    end
  end
end
