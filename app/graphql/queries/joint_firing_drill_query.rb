module Queries
  class JointFiringDrillQuery < Queries::BaseQuery
    type Types::JointFiringDrillType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      JointFiringDrill.find_by(uid: uid)
    end
  end
end
