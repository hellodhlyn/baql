# frozen_string_literal: true

module Types
  module Inputs
    class DefenseTypeInput < Types::Base::InputObject
      argument :defense_type, Types::Enums::DefenseType, required: true
      argument :difficulty, Types::Enums::DifficultyType, required: true
    end
  end
end
