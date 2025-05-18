module Queries
  class RaidQuery < Queries::BaseQuery
    type Types::RaidType, null: true

    # [DEPRECATED v1] Use `uid` instead
    argument :raid_id, String, required: false
    argument :uid, String, required: false

    def resolve(raid_id: nil, uid: nil)
      raid_uid = raid_id || uid
      raise GraphQL::ExecutionError, "Either raid_id or uid must be provided" if raid_uid.blank?

      Raid.find_by(uid: raid_uid)
    end
  end
end
