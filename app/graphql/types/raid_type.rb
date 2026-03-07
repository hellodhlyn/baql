module Types
  class RaidType < Types::Base::Object
    implements GraphQL::Types::Relay::Node
    implements Types::ContentInterface

    class RaidTypeEnum < Types::Base::Enum
      Raid::RAID_TYPES.each do |type|
        value type, value: type
      end
    end

    class DefenseTypeAndDifficulty < Types::Base::Object
      field :defense_type, Types::Enums::DefenseType, null: false
      field :difficulty, Types::Enums::DifficultyType, null: true
    end

    field :type, RaidTypeEnum, null: false
    field :name, String, null: false
    field :boss, String, null: false
    field :terrain, Types::Enums::TerrainType, null: false
    field :attack_type, Types::Enums::AttackType, null: false
    field :defense_types, [DefenseTypeAndDifficulty], null: false
    field :raid_index_jp, Integer, null: true
    field :rank_visible, Boolean, null: false

    # ==== Videos ====
    class VideoSortEnum < Types::Base::Enum
      value "PUBLISHED_AT_DESC", value: "PUBLISHED_AT_DESC"
      value "SCORE_DESC", value: "SCORE_DESC"
    end

    field :videos, Types::RaidVideoType.connection_type, null: false do
      argument :sort, VideoSortEnum, required: false, default_value: "PUBLISHED_AT_DESC"
    end

    def videos(after: nil, first: 20, sort: "PUBLISHED_AT_DESC")
      query = RaidVideo.of(raid_uid: object.uid)
      case sort
      when "SCORE_DESC"
        query.order(score: :desc)
      when "PUBLISHED_AT_DESC", nil
        query.order(published_at: :desc)
      else
        query.order(published_at: :desc) # fallback to default
      end
    end
  end
end
