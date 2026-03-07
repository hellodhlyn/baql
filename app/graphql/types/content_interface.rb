module Types
  module ContentInterface
    include Types::Base::Interface

    field :uid, String, null: false
    field :name, String, null: false
    field :confirmed, Boolean, null: false
    field :since,     GraphQL::Types::ISO8601DateTime, null: false, deprecation_reason: "Use startAt instead"
    field :until,     GraphQL::Types::ISO8601DateTime, null: false, deprecation_reason: "Use endAt instead"
    field :start_at,  GraphQL::Types::ISO8601DateTime, null: false, method: :since
    field :end_at,    GraphQL::Types::ISO8601DateTime, null: false, method: :until

    definition_methods do
      def resolve_type(object, context)
        case object
        when Event then Types::EventType
        when Raid  then Types::RaidType
        else raise "Unexpected object: #{object}"
        end
      end
    end
  end
end
