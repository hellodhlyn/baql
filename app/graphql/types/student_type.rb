module Types
  class StudentType < Types::Base::Object
    class RoleEnum < Types::Base::Enum
      value "striker", value: "striker"
      value "special", value: "special"
    end

    field :uid, String, null: false
    field :name, String, null: false
    field :school, String, null: false
    field :initial_tier, Int, null: false
    field :attack_type, Types::Enums::AttackType, null: false
    field :defense_type, Types::Enums::DefenseType, null: false
    field :role, RoleEnum, null: false
    field :equipments, [String], null: false
    field :released, Boolean, null: false
    field :order, Int, null: false
    field :schale_db_id, String, null: true

    field :raid_statistics, [Types::RaidStatisticsType], null: false do
      argument :raid_since, GraphQL::Types::ISO8601DateTime, required: false
    end
    def raid_statistics(raid_since: nil)
      query = RaidStatistics.where(student_uid: object.uid).joins(:raid)
      query = query.where({ raid: { since: raid_since... } }) if raid_since.present?
      query.order(raid: { since: :asc })
    end

    field :pickups, [Types::PickupType], null: false
    def pickups
      Pickup.where(student_uid: object.uid).order(since: :asc)
    end

    field :skill_items, [Types::SkillItemType], null: false do
      argument :skill_type, Types::SkillItemType::SkillTypeEnum, required: false
      argument :skill_level, Int, required: false
    end
    def skill_items(skill_type: nil, skill_level: nil)
      query = StudentSkillItem.includes(:item).where(student_uid: object.uid)
      query = query.where(skill_type: skill_type) if skill_type.present?
      query = query.where(skill_level: skill_level) if skill_level.present?
      query.order(skill_type: :asc, skill_level: :asc)
    end

    field :favorite_items, [Types::FavoriteItemType], null: false do
      argument :favorited, Boolean, required: false
    end
    def favorite_items(favorited: nil)
      query = StudentFavoriteItem.includes(:item).where(student_uid: object.uid)
      query = query.where(favorited: favorited) if favorited.present?
      query.order(favorite_level: :desc)
    end
  end
end
