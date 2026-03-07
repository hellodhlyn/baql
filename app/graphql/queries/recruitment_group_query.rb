module Queries
  class RecruitmentGroupQuery < Queries::BaseQuery
    type Types::RecruitmentGroupType, null: true

    argument :content_uid, String, required: true

    def resolve(content_uid:)
      RecruitmentGroup
        .includes(:recruitments, recruitments: :student)
        .find_by(content_uid: content_uid)
    end
  end
end
