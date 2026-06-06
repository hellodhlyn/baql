# frozen_string_literal: true

module Types
  module Inputs
    class DefenseTypeSetInput < Types::Base::InputObject
      argument :defense_types, [Types::Enums::DefenseType], required: true
      argument :difficulty, Types::Enums::DifficultyType, required: false
    end
  end
end
