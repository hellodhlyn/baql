module Types
  class MiniEventContentScheduleType < Types::Base::Object
    field :region,     String,                          null: false
    field :occurrence, Integer,                         null: false
    field :start_at,   GraphQL::Types::ISO8601DateTime, null: false
    field :end_at,     GraphQL::Types::ISO8601DateTime, null: false
  end

  class MiniEventContentType < Types::Base::Object
    field :uid,       String,                              null: false
    field :name,      String,                              null: false
    field :schedules, [Types::MiniEventContentScheduleType], null: false

    def name
      dataloader
        .with(Sources::TranslationByKey, Constants::DEFAULT_LANGUAGE)
        .load("#{object.translation_key_prefix}::name")
    end

    def schedules
      dataloader
        .with(Sources::RecordsByForeignKey, MiniEventContentSchedule, :mini_event_content_uid, order: :occurrence)
        .load(object.uid)
    end
  end
end
