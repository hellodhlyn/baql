# frozen_string_literal: true

module Mutations
  module EventContentSchedules
    class UpsertEventContentSchedule < Mutations::BaseMutation
      argument :event_content_uid, String, required: true
      argument :region, Types::Enums::RegionType, required: true
      argument :run_type, Types::Enums::EventScheduleRunTypeEnum, required: true
      argument :start_at, GraphQL::Types::ISO8601DateTime, required: true
      argument :end_at, GraphQL::Types::ISO8601DateTime, required: false

      field :event_content_schedule, Types::EventContentScheduleType, null: true

      def resolve(event_content_uid:, region:, run_type:, start_at:, end_at: nil)
        schedule = EventContentSchedule.find_or_initialize_by(
          event_content_uid: event_content_uid,
          region: region,
          run_type: run_type,
        )
        schedule.assign_attributes(start_at: start_at, end_at: end_at)
        save_record(schedule, event_content_schedule: schedule)
      end
    end
  end
end
