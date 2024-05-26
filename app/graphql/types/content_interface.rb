module Types
  module ContentInterface
    include Types::Base::Interface

    field :name, String, null: false
    field :since, GraphQL::Types::ISO8601DateTime, null: false
    field :until, GraphQL::Types::ISO8601DateTime, null: false

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
