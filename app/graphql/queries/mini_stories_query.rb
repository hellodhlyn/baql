# frozen_string_literal: true

module Queries
  class MiniStoriesQuery < Queries::BaseQuery
    type [Types::MiniStoryType], null: false

    argument :region,         Types::Enums::RegionType,        required: false
    argument :released_after, GraphQL::Types::ISO8601DateTime, required: false

    def resolve(region: nil, released_after: nil)
      scope = MiniStory.all

      if region.present? || released_after.present?
        scope = scope.joins(:schedules)
        scope = scope.where(mini_story_schedules: { region: region }) if region.present?
        scope = scope.where("mini_story_schedules.released_at >= ?", released_after) if released_after.present?

        return scope.order("mini_story_schedules.released_at ASC, mini_stories.id ASC") if region.present?

        return scope.distinct.order(:id)
      end

      scope.order(:id)
    end
  end
end
