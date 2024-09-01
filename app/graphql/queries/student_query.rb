module Queries
  class StudentQuery < Queries::BaseQuery
    type Types::StudentType, null: false

    argument :student_id, String, required: true

    def resolve(student_id:)
      Student.find_by_student_id(student_id)
    end
  end
end
