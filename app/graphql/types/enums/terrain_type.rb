module Types
  module Enums
    class TerrainType < Types::Base::Enum
      Raid::TERRAINS.each do |type|
        value type, value: type
      end
    end
  end
end
