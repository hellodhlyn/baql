module Types
  module Enums
    class AttackType < Types::Base::Enum
      Battleable::ATTACK_TYPES.each do |type|
        value type, value: type
      end
    end
  end
end
