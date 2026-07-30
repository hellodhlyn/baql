module Types
  class RaidBossType < Types::Base::Object
    implements GraphQL::Types::Relay::Node

    field :uid, String, null: false
    field :name, String, null: false do
      argument :lang, String, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :raid_type, String, null: false
    field :event_content, Types::EventContentType, null: true
    field :schedules, [Types::RaidScheduleType], null: false

    def name(lang: Constants::DEFAULT_LANGUAGE)
      dataloader
        .with(Sources::TranslationByKey, lang)
        .load("#{object.translation_key_prefix}::name")
    end

    def event_content
      return nil unless object.event_content_uid

      dataloader
        .with(Sources::RecordByUid, EventContent, columns: [:uid, :baql_id])
        .load(object.event_content_uid)
    end

    def schedules
      dataloader
        .with(Sources::RecordsByForeignKey, RaidSchedule, :raid_boss_uid)
        .load(object.uid)
    end

  end
end
