# frozen_string_literal: true

module Sources
  class StudentNameByStudent < GraphQL::Dataloader::Source
    def initialize(language)
      @language = language
    end

    def fetch(students)
      keys = students.map { |student| "#{student.translation_key_prefix}::name" }
      translations = Translation.where(key: keys, language: @language).index_by(&:key)

      students.map do |student|
        key = "#{student.translation_key_prefix}::name"
        translations[key]&.value || student.read_attribute(:name)
      end
    end
  end
end
