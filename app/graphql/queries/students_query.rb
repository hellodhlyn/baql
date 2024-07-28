module Queries
  class StudentsQuery < Queries::BaseQuery
    type [Types::StudentType], null: false

    argument :student_ids, [String], required: false

    def resolve(student_ids: [])
      if student_ids.present?
        Student.where(student_id: student_ids)
      else
        Student.all_without_multiclass
      end
    end
  end
end
