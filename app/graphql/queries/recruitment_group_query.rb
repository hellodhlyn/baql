module Queries
  class RecruitmentGroupQuery < Queries::BaseQuery
    type Types::RecruitmentGroupType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      RecruitmentGroup
        .includes(:recruitments, recruitments: :student)
        .find_by(uid: uid)
    end
  end
end
