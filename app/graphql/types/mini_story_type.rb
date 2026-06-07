# frozen_string_literal: true

module Types
  class MiniStoryScheduleType < Types::Base::Object
    field :region,      String,                          null: false
    field :released_at, GraphQL::Types::ISO8601DateTime, null: false
  end

  class MiniStoryType < Types::Base::Object
    field :uid,           String,                         null: false
    field :title,         String,                         null: true do
      argument :language, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :episode_count, Integer,                        null: false
    field :schedules,     [Types::MiniStoryScheduleType], null: false

    def title(language:)
      dataloader
        .with(Sources::TranslationByKey, language)
        .load("#{object.translation_key_prefix}::title")
    end

    def schedules
      dataloader
        .with(Sources::RecordsByForeignKey, MiniStorySchedule, :mini_story_uid, order: :region)
        .load(object.uid)
    end
  end
end
