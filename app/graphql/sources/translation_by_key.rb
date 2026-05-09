# frozen_string_literal: true

module Sources
  class TranslationByKey < GraphQL::Dataloader::Source
    def initialize(language)
      @language = language
    end

    def fetch(keys)
      translations = Translation.where(key: keys, language: @language).index_by(&:key)

      keys.map { |key| translations[key]&.value }
    end
  end
end
