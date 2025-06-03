module Queries
  class StudentQuery < Queries::BaseQuery
    type Types::StudentType, null: false

    argument :uid, String, required: true

    def resolve(uid: nil)
      Student.find_by_uid(uid)
    end
  end
end
