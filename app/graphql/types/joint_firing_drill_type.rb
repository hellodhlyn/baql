module Types
  class JointFiringDrillScheduleType < Types::Base::Object
    field :region,   String,                          null: false
    field :start_at, GraphQL::Types::ISO8601DateTime, null: false
    field :end_at,   GraphQL::Types::ISO8601DateTime, null: true
  end

  class JointFiringDrillType < Types::Base::Object
    class DrillTypeEnum < Types::Base::Enum
      JointFiringDrill::DRILL_TYPES.each { |t| value t, value: t }
    end

    field :uid,          String,                           null: false
    field :season,       Integer,                          null: false
    field :drill_type,   DrillTypeEnum,                    null: false
    field :terrain,      Types::Enums::TerrainType,        null: false
    field :defense_type, Types::Enums::DefenseType,        null: false
    field :confirmed,    Boolean,                          null: false
    field :schedules,    [Types::JointFiringDrillScheduleType], null: false
  end
end
