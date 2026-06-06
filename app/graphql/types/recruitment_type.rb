module Types
  class RecruitmentType < Types::Base::Object
    field :uid,               String,              null: false
    field :recruitment_group, "Types::RecruitmentGroupType", null: false
    field :recruitment_type,  RecruitmentTypeEnum, null: false
    field :pickup,            Boolean,             null: false
    field :student_name,      String,              null: false
    field :rerun,             Boolean,             null: false
    field :student,           "Types::StudentType", null: true

    field :since, GraphQL::Types::ISO8601DateTime, null: false, method: :start_at  # deprecated
    field :until, GraphQL::Types::ISO8601DateTime, null: true, method: :end_at     # deprecated
    field :start_at, GraphQL::Types::ISO8601DateTime, null: false
    field :end_at, GraphQL::Types::ISO8601DateTime, null: true

    def student_name
      if object.association(:student).loaded?
        object.student&.name || object.student_name
      elsif object.student_uid.present?
        dataloader
          .with(Sources::RecordByUid, Student)
          .load(object.student_uid)
          .then { |student| student&.name || object.student_name }
      else
        object.student_name
      end
    end

    def student
      if object.association(:student).loaded?
        object.student
      else
        return nil unless object.student_uid.present?

        dataloader
          .with(Sources::RecordByUid, Student)
          .load(object.student_uid)
      end
    end
  end
end
