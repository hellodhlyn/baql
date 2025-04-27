module Queries
  class StudentQuery < Queries::BaseQuery
    type Types::StudentType, null: true

    argument :student_id, String, required: false # [REMOVE IN v1] Use `uid` instead
    argument :uid, String, required: false

    def resolve(student_id: nil, uid: nil)
      Student.find_by_uid(uid || student_id)
    end
  end
end
