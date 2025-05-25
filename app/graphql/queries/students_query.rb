module Queries
  class StudentsQuery < Queries::BaseQuery
    type [Types::StudentType], null: false

    # [DEPRECATED v1] Use `uids` instead
    argument :student_ids, [String], required: false
    argument :uids, [String], required: false

    def resolve(student_ids: [], uids: [])
      if student_ids.present? || uids.present?
        Student.where(uid: (student_ids || []) + (uids || []))
      else
        Student.all_without_multiclass
      end
    end
  end
end
