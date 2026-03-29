# frozen_string_literal: true

module Mutations
  module JointFiringDrillSchedules
    class UpsertJointFiringDrillSchedule < Mutations::BaseMutation
      argument :drill_uid, String,                          required: true
      argument :region,    Types::Enums::RegionType,        required: true
      argument :start_at,  GraphQL::Types::ISO8601DateTime, required: true
      argument :end_at,    GraphQL::Types::ISO8601DateTime, required: false

      field :joint_firing_drill_schedule, "Types::JointFiringDrillScheduleType", null: true

      def resolve(drill_uid:, region:, start_at:, end_at: nil)
        schedule = JointFiringDrillSchedule.find_or_initialize_by(
          drill_uid: drill_uid,
          region: region,
        )
        schedule.assign_attributes(start_at: start_at, end_at: end_at)
        save_record(schedule, joint_firing_drill_schedule: schedule)
      end
    end
  end
end
