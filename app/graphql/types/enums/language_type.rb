# frozen_string_literal: true

module Types
  module Enums
    class LanguageType < Types::Base::Enum
      Constants::LANGUAGES.each { |language| value language, value: language }
    end
  end
end
