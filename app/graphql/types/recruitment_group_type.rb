module Types
  class RecruitmentGroupType < Types::Base::Object
    field :uid,          String,                          null: false
    field :start_at,     GraphQL::Types::ISO8601DateTime, null: false
    field :end_at,       GraphQL::Types::ISO8601DateTime, null: true
    field :recruitment_type, Types::RecruitmentTypeEnum,  null: false
    field :content_type,     String,                      null: true
    field :content_uid,  String,                          null: true
    field :recruitments, [Types::RecruitmentType],        null: false

    def recruitments
      if object.association(:recruitments).loaded?
        object.recruitments.sort_by(&:id)
      else
        object.recruitments.order(:id)
      end
    end
  end
end
