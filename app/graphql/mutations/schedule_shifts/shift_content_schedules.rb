# frozen_string_literal: true

module Mutations
  module ScheduleShifts
    class ShiftContentSchedules < Mutations::BaseMutation
      argument :cutoff, GraphQL::Types::ISO8601DateTime, required: true
      argument :days, Integer, required: true
      argument :direction, Types::Enums::ScheduleShiftDirectionEnum, required: true
      argument :dry_run, Boolean, required: false, default_value: true

      field :dry_run, Boolean, null: false
      field :total_rows, Integer, null: false
      field :schedule_updates, [Types::ScheduleShiftUpdateType], null: false
      field :student_release_updates, [Types::StudentRecruitmentDateUpdateType], null: false

      def resolve(cutoff:, days:, direction:, dry_run:)
        raise GraphQL::ExecutionError, "days must be a positive integer" unless days.positive?

        shift_by = direction == "advance" ? -days.days : days.days
        result = Maintenance::GlScheduleShift.new(
          cutoff: cutoff,
          shift_by: shift_by,
          dry_run: dry_run,
        ).call

        {
          dry_run: result.dry_run,
          total_rows: result.total_rows,
          schedule_updates: serialize_schedule_updates(result.schedule_updates),
          student_release_updates: serialize_student_release_updates(result.student_release_updates),
          errors: [],
        }
      end

      private

      def serialize_schedule_updates(updates)
        updates.map do |update|
          {
            schedule_type: update.label,
            identifier: update.identifier,
            changes: update.changes.map do |column, (before, after)|
              { column: column.to_s, before: before, after: after }
            end,
          }
        end
      end

      def serialize_student_release_updates(updates)
        updates.map do |update|
          {
            uid: update.uid,
            recruitment_group_uid: update.recruitment_group_uid,
            before_release_at: update.before[:release_at],
            after_release_at: update.after[:release_at],
            before_archive_at: update.before[:archive_at],
            after_archive_at: update.after[:archive_at],
          }
        end
      end
    end
  end
end
