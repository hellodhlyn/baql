module Queries
  class StageQuery < Queries::BaseQuery
    type Types::StageType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      Stage.find_by(uid: uid)
    end
  end
end
