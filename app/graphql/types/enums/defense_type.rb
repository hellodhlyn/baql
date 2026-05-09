module Types
  module Enums
    class DefenseType < Types::Base::Enum
      Battleable::DEFENSE_TYPES.each do |type|
        value type, value: type
      end
    end
  end
end
