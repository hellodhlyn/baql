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
      object.name(lang)
    end
  end
end
