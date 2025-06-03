module Queries
  class RaidQuery < Queries::BaseQuery
    type Types::RaidType, null: true

    argument :uid, String, required: true

    def resolve(uid: nil)
      Raid.find_by(uid: uid)
    end
  end
end
