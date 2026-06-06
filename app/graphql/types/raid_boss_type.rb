module Types
  class RaidBossType < Types::Base::Object
    implements GraphQL::Types::Relay::Node

    field :uid, String, null: false
    field :name, String, null: false do
      argument :lang, String, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :raid_type, String, null: false
    field :event_content, Types::EventContentType, null: true, extras: [:lookahead]
    field :schedules, [Types::RaidScheduleType], null: false

    def name(lang: Constants::DEFAULT_LANGUAGE)
      dataloader
        .with(Sources::TranslationByKey, lang)
        .load("#{object.translation_key_prefix}::name")
    end

    def event_content(lookahead:)
      return nil unless object.event_content_uid

      dataloader
        .with(Sources::RecordByUid, EventContent, columns: event_content_columns_for(lookahead))
        .load(object.event_content_uid)
    end

    def schedules
      dataloader
        .with(Sources::RecordsByForeignKey, RaidSchedule, :raid_boss_uid)
        .load(object.uid)
    end

    private

    def event_content_columns_for(lookahead)
      columns = [:uid, :baql_id]
      columns.concat([:raw_data_first, :raw_data_rerun]) if raw_event_content_data_selected?(lookahead)
      columns
    end

    def raw_event_content_data_selected?(lookahead)
      %i[
        raw_data_first
        raw_data_rerun
        stages
        bonuses
        shop_resources
        minigame_configs
      ].any? { |field| lookahead.selects?(field) }
    end
  end
end
