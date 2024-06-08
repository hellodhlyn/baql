module Types
  module Enums
    class AttackType < Types::Base::Enum
      Raid::ATTACK_TYPES.each do |type|
        value type, value: type
      end
    end
  end
end
