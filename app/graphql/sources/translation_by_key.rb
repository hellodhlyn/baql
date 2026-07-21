# frozen_string_literal: true

module Sources
  class TranslationByKey < GraphQL::Dataloader::Source
    def initialize(language, fallback_language: nil)
      @language = language
      @fallback_language = fallback_language
    end

    def fetch(keys)
      languages = [@language, @fallback_language].compact.uniq
      translations = Translation.where(key: keys, language: languages).index_by do |translation|
        [translation.key, translation.language]
      end

      keys.map do |key|
        translations[[key, @language]]&.value || translations[[key, @fallback_language]]&.value
      end
    end
  end
end
