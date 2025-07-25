module Types
  class PickupTypeEnum < Types::Base::Enum
    ::Pickup::PICKUP_TYPES.each do |type|
      value type, value: type
    end
  end

  class PickupType < Types::Base::Object
    field :type, PickupTypeEnum, null: false
    field :rerun, Boolean, null: false

    field :student, "Types::StudentType", null: true
    def student
      # Use preloaded association if available
      if object.association(:student).loaded?
        object.student
      else
        object.student_uid.present? ? Student.find_by_uid(object.student_uid) : nil
      end
    end

    field :student_name, String, null: false
    field :event, "Types::EventType", null: false
    field :since, GraphQL::Types::ISO8601DateTime, null: false
    field :until, GraphQL::Types::ISO8601DateTime, null: true
  end
end
