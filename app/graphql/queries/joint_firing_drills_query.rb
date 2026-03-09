# frozen_string_literal: true

module Queries
  class JointFiringDrillsQuery < Queries::BaseQuery
    type [Types::JointFiringDrillType], null: false

    argument :end_after,    GraphQL::Types::ISO8601DateTime, required: false
    argument :start_before, GraphQL::Types::ISO8601DateTime, required: false

    def resolve(end_after: nil, start_before: nil)
      drills = JointFiringDrill.includes(:schedules).order(season: :asc)

      if end_after.present? || start_before.present?
        drills = drills.joins(:schedules)
        drills = drills.where("joint_firing_drill_schedules.end_at >= ?", end_after)    if end_after.present?
        drills = drills.where("joint_firing_drill_schedules.start_at < ?", start_before) if start_before.present?
        drills = drills.distinct
      end

      drills
    end
  end
end
