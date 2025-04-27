module Queries
  class StudentsQuery < Queries::BaseQuery
    type [Types::StudentType], null: false

    argument :student_ids, [String], required: false # [REMOVE IN v1] Use `uids` instead
    argument :uids, [String], required: false

    def resolve(student_ids: [], uids: [])
      if uids.present?
        Student.where(uid: uids || student_ids)
      else
        Student.all_without_multiclass
      end
    end
  end
end
