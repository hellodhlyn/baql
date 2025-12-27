module Types
  class RecruitmentTypeEnum < Types::Base::Enum
    ::Pickup::PICKUP_TYPES.each do |type|
      value type, value: type
    end
  end

  class RecruitmentType < Types::Base::Object
    field :recruitment_type, RecruitmentTypeEnum, null: false
    def recruitment_type = object.type

    field :rerun, Boolean, null: false
    field :pickup, Boolean, null: false
    def pickup
      event_type = object.event.type
      if event_type == "fes"
        (object.type == "fes" && !object.rerun) || (object.type == "limited" && object.rerun)
      elsif object.type == "given"
        false
      else
        true
      end
    end

    field :student_name, String, null: false
    field :student, "Types::StudentType", null: true
    def student
      # Use preloaded association if available
      if object.association(:student).loaded?
        object.student
      else
        object.student_uid.present? ? Student.find_by_uid(object.student_uid) : nil
      end
    end

    field :event, "Types::EventType", null: false
    field :since, GraphQL::Types::ISO8601DateTime, null: false
    field :until, GraphQL::Types::ISO8601DateTime, null: true
  end
end
