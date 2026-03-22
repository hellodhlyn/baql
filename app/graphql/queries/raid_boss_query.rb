module Queries
  class RaidBossQuery < Queries::BaseQuery
    type Types::RaidBossType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      RaidBoss.find_by(uid: uid)
    end
  end
end
