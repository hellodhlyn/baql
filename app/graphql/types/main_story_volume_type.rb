module Types
  class MainStoryPartScheduleType < Types::Base::Object
    field :region,      String,                            null: false
    field :released_at, GraphQL::Types::ISO8601DateTime,   null: false
    field :confirmed,   Boolean,                           null: false
  end

  class MainStoryPartType < Types::Base::Object
    field :uid,           String, null: false
    field :name,          String, null: true do
      argument :language, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :sort_order,    Int,    null: false
    field :episode_start, Int,    null: true
    field :episode_end,   Int,    null: true
    field :schedules,     [Types::MainStoryPartScheduleType], null: false

    def name(language:)
      dataloader
        .with(Sources::TranslationByKey, language)
        .load("#{object.translation_key_prefix}::name")
    end

    def schedules
      dataloader
        .with(Sources::RecordsByForeignKey, MainStoryPartSchedule, :part_uid, order: :region)
        .load(object.uid)
    end
  end

  class MainStoryChapterType < Types::Base::Object
    field :uid,            String, null: false
    field :name,           String, null: true do
      argument :language, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :chapter_number, Int,    null: false
    field :parts,          [Types::MainStoryPartType], null: false

    def name(language:)
      dataloader
        .with(Sources::TranslationByKey, language)
        .load("#{object.translation_key_prefix}::name")
    end

    def parts
      dataloader
        .with(Sources::RecordsByForeignKey, MainStoryPart, :chapter_uid, order: :sort_order)
        .load(object.uid)
    end
  end

  class MainStoryVolumeType < Types::Base::Object
    field :uid,        String, null: false
    field :season,     Int,    null: false
    field :label,      String, null: false
    field :name,       String, null: true do
      argument :language, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :sort_order, Int,    null: false
    field :chapters,   [Types::MainStoryChapterType], null: false

    def name(language:)
      dataloader
        .with(Sources::TranslationByKey, language)
        .load("#{object.translation_key_prefix}::name")
    end

    def chapters
      dataloader
        .with(Sources::RecordsByForeignKey, MainStoryChapter, :volume_uid, order: :chapter_number)
        .load(object.uid)
    end
  end
end
