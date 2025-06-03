module Queries
  class StudentsQuery < Queries::BaseQuery
    type [Types::StudentType], null: false

    argument :uids, [String], required: false

    def resolve(uids: [])
      if uids.present?
        Student.where(uid: uids)
      else
        Student.all_without_multiclass
      end
    end
  end
end
