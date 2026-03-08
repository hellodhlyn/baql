module Types
  class RecruitmentTypeEnum < Types::Base::Enum
    ::Recruitment::RECRUITMENT_TYPES.each do |type|
      value type, value: type
    end
  end

  class RecruitmentType < Types::Base::Object
    field :uid,               String,              null: false
    field :recruitment_group, "Types::RecruitmentGroupType", null: false
    field :recruitment_type,  RecruitmentTypeEnum, null: false
    field :pickup,            Boolean,             null: false
    field :student_name,      String,              null: false
    field :student,           "Types::StudentType", null: true

    # backward compat: these live on RecruitmentGroup in v2
    field :since, GraphQL::Types::ISO8601DateTime, null: false
    field :until, GraphQL::Types::ISO8601DateTime, null: true
    field :rerun, Boolean, null: false
    field :event, "Types::EventType", null: true

    def event
      group_uid = object.recruitment_group.uid
      Event.find_by(uid: group_uid) || Event.find_by(uid: group_uid.sub(/-\d{8}$/, ""))
    end

    def since
      object.recruitment_group.start_at
    end

    def until
      object.recruitment_group.end_at
    end

    def student_name
      object.student&.name || object.student_name
    end

    def student
      if object.association(:student).loaded?
        object.student
      else
        object.student_uid.present? ? Student.find_by_uid(object.student_uid) : nil
      end
    end
  end
end
