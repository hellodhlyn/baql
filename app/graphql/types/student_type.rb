module Types
  class StudentType < Types::Base::Object
    class RoleEnum < Types::Base::Enum
      value "striker", value: "striker"
      value "special", value: "special"
    end

    # [DEPRECATED v1] Use `uid` instead
    field :student_id, String, null: false
    def student_id = object.uid

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
    field :schale_db_id, String, null: false

    field :raid_statistics, [Types::RaidStatisticsType], null: false do
      argument :raid_since, GraphQL::Types::ISO8601DateTime, required: false
    end

    def raid_statistics(raid_since: nil)
      query = RaidStatistics.where(student_uid: object.uid).joins(:raid)
      query = query.where({ raid: { since: raid_since... } }) if raid_since.present?
      query.order(raid: { since: :asc })
    end
  end
end
