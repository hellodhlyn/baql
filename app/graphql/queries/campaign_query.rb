# frozen_string_literal: true

module Queries
  class CampaignQuery < Queries::BaseQuery
    type Types::CampaignType, null: true

    argument :uid,    String, required: true
    argument :region, String, required: false

    def resolve(uid:, region: nil)
      scope = Campaign.where(uid: uid)
      scope = scope.where(region: region) if region.present?
      scope.first
    end
  end
end
