module Types
  module Enums
    class DefenseType < Types::Base::Enum
      Raid::DEFENSE_TYPES.each do |type|
        value type, value: type
      end
    end
  end
end
