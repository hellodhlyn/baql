# frozen_string_literal: true

module Types
  module Inputs
    class TranslationInput < Types::Base::InputObject
      argument :language, Types::Enums::LanguageType, required: true
      argument :value,    String,                     required: true
    end
  end
end
