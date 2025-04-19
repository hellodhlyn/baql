module Types
  module Enums
    class DifficultyType < Types::Base::Enum
      Raid::DIFFICULTIES.each do |type|
        value type, value: type
      end
    end
  end
end
