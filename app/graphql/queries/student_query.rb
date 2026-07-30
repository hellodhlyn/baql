module Queries
  class StudentQuery < Queries::BaseQuery
    type Types::StudentType, null: true

    argument :uid, String, required: true

    def resolve(uid: nil)
      Student.find_jp_released_by_uid(uid)
    end
  end
end
