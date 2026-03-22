module Queries
  class RaidScheduleQuery < Queries::BaseQuery
    type Types::RaidScheduleType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      RaidSchedule.find_by(uid: uid)
    end
  end
end
