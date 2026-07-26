module Types
  class StudentClubType < Types::Base::Object
    TRANSLATION_KEY_PREFIX = "baql::student_clubs::"

    field :uid, String, null: false
    field :name, String, null: true do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end

    def name(lang:)
      dataloader
        .with(Sources::TranslationByKey, lang, fallback_language: Constants::DEFAULT_LANGUAGE)
        .load("#{TRANSLATION_KEY_PREFIX}#{object.uid}::name")
    end
  end
end
