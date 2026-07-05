# frozen_string_literal: true

module Mutations
  module MainStoryPartSchedules
    class UpsertMainStoryPartSchedule < Mutations::BaseMutation
      argument :part_uid,    String,                          required: true
      argument :region,      Types::Enums::RegionType,        required: true
      argument :released_at, GraphQL::Types::ISO8601DateTime, required: true
      argument :confirmed,   Boolean,                         required: false

      field :main_story_part_schedule, "Types::MainStoryPartScheduleType", null: true

      def resolve(part_uid:, region:, released_at:, confirmed: nil)
        schedule = MainStoryPartSchedule.find_or_initialize_by(
          part_uid: part_uid,
          region: region,
        )
        schedule.released_at = released_at
        schedule.confirmed = confirmed unless confirmed.nil?
        save_record(schedule, main_story_part_schedule: schedule)
      end
    end
  end
end
