module Queries
  class RecruitmentGroupsQuery < Queries::BaseQuery
    type [Types::RecruitmentGroupType], null: false

    argument :uids, [String], required: false
    argument :start_before, GraphQL::Types::ISO8601DateTime, required: false
    argument :end_after, GraphQL::Types::ISO8601DateTime, required: false

    def resolve(uids: nil, start_before: nil, end_after: nil)
      scope = RecruitmentGroup
        .includes(:recruitments, recruitments: :student)
        .order(start_at: :asc)
      scope = scope.where(uid: uids) if uids.present?
      scope = scope.where("start_at <= ?", start_before) if start_before.present?
      scope = scope.where("end_at >= ?", end_after) if end_after.present?
      scope
    end
  end
end
