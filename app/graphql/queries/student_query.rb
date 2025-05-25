module Queries
  class StudentQuery < Queries::BaseQuery
    type Types::StudentType, null: false

    # [DEPRECATED v1] Use `uid` instead
    argument :student_id, String, required: true
    argument :uid, String, required: false

    def resolve(student_id: nil, uid: nil)
      student_uid = uid || student_id
      Student.find_by_uid(student_uid)
    end
  end
end
