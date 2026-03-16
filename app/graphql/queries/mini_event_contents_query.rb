module Queries
  class MiniEventContentsQuery < Queries::BaseQuery
    type [Types::MiniEventContentType], null: false

    argument :region,    String,                          required: false
    argument :end_after, GraphQL::Types::ISO8601DateTime, required: false

    def resolve(region: nil, end_after: nil)
      scope = MiniEventContent.includes(:schedules)

      if region.present? || end_after.present?
        scope = scope.joins(:schedules)
        scope = scope.where(mini_event_content_schedules: { region: region }) if region.present?
        scope = scope.where("mini_event_content_schedules.end_at >= ?", end_after) if end_after.present?
        scope = scope.distinct
      end

      scope
    end
  end
end
