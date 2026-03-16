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
  end
end
