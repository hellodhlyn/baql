# frozen_string_literal: true

module Queries
  class JointFiringDrillsQuery < Queries::BaseQuery
    type [Types::JointFiringDrillType], null: false

    argument :until_after,  GraphQL::Types::ISO8601DateTime, required: false # deprecated: use endAfter
    argument :since_before, GraphQL::Types::ISO8601DateTime, required: false # deprecated: use startBefore
    argument :end_after,    GraphQL::Types::ISO8601DateTime, required: false
    argument :start_before, GraphQL::Types::ISO8601DateTime, required: false

    def resolve(until_after: nil, since_before: nil, end_after: nil, start_before: nil)
      drills = JointFiringDrill.includes(:schedules).order(season: :asc)

      effective_end_after    = end_after    || until_after
      effective_start_before = start_before || since_before

      if effective_end_after.present? || effective_start_before.present?
        drills = drills.joins(:schedules)
        drills = drills.where("joint_firing_drill_schedules.end_at >= ?", effective_end_after)    if effective_end_after.present?
        drills = drills.where("joint_firing_drill_schedules.start_at < ?", effective_start_before) if effective_start_before.present?
        drills = drills.distinct
      end

      drills
    end
  end
end
