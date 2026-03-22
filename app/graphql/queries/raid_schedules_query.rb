module Queries
  class RaidSchedulesQuery < Queries::BaseQuery
    type Types::RaidScheduleType.connection_type, null: false

    argument :region,       String,                           required: true
    argument :raid_type,    String,                           required: false
    argument :uids,         [String],                         required: false
    argument :end_after,    GraphQL::Types::ISO8601DateTime,  required: false
    argument :start_before, GraphQL::Types::ISO8601DateTime,  required: false

    def resolve(region:, raid_type: nil, uids: nil, end_after: nil, start_before: nil)
      results = RaidSchedule.where(region: region).order(start_at: :asc)
      results = results.where(raid_type: raid_type)       if raid_type.present?
      results = results.where(uid: uids)                  if uids.present?
      results = results.where("end_at >= ?",   end_after)    if end_after.present?
      results = results.where("start_at < ?",  start_before) if start_before.present?
      results
    end
  end
end
