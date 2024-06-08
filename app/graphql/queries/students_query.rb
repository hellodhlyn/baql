module Queries
  class StudentsQuery < Queries::BaseQuery
    type [Types::StudentType], null: false

    argument :student_ids, [String], required: false

    def resolve(student_ids: [])
      results = Student.all
      results = results.where(student_id: student_ids) if student_ids.present?
      results
    end
  end
end
