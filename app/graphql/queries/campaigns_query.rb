# frozen_string_literal: true

module Queries
  class CampaignsQuery < Queries::BaseQuery
    type [Types::CampaignType], null: false

    argument :region,    String,                          required: true
    argument :end_after, GraphQL::Types::ISO8601DateTime, required: false

    def resolve(region: nil, end_after: nil)
      scope = Campaign.order(start_at: :asc)
      scope = scope.where(region: region)           if region.present?
      scope = scope.where("end_at >= ?", end_after) if end_after.present?
      scope
    end
  end
end
