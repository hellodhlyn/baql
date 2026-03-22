module Types
  class RaidScheduleType < Types::Base::Object
    field :uid, String, null: false
    field :raid_boss, Types::RaidBossType, null: false
    field :region, String, null: false
    field :raid_type, String, null: false
    field :season_index, Integer, null: false
    field :terrain, Types::Enums::TerrainType, null: false
    field :start_at, GraphQL::Types::ISO8601DateTime, null: true
    field :end_at, GraphQL::Types::ISO8601DateTime, null: true
    field :attack_type, Types::Enums::AttackType, null: true
    field :defense_types, [Types::RaidType::DefenseTypeAndDifficulty], null: false
    field :jp_schedule, Types::RaidScheduleType, null: true
    field :videos, Types::RaidVideoType.connection_type, null: false do
      argument :sort, Types::RaidType::VideoSortEnum, required: false, default_value: "PUBLISHED_AT_DESC"
    end

    def videos(after: nil, first: 20, sort: "PUBLISHED_AT_DESC")
      query = object.videos
      case sort
      when "SCORE_DESC"        then query.order(score: :desc)
      when "PUBLISHED_AT_DESC" then query.order(published_at: :desc)
      else                          query.order(published_at: :desc)
      end
    end
  end
end
