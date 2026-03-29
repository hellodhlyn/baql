# frozen_string_literal: true

module Mutations
  module Campaigns
    class UpdateCampaign < Mutations::BaseMutation
      argument :uid,        String,                          required: true
      argument :region,     Types::Enums::RegionType,        required: true
      argument :category,   [Types::CampaignType::CategoryEnum], required: false
      argument :multiplier, Integer,                         required: false
      argument :start_at,   GraphQL::Types::ISO8601DateTime, required: false
      argument :end_at,     GraphQL::Types::ISO8601DateTime, required: false

      field :campaign, Types::CampaignType, null: true

      def resolve(uid:, region:, **attrs)
        campaign = Campaign.find_by(uid: uid, region: region)
        raise GraphQL::ExecutionError, "Campaign with uid '#{uid}' and region '#{region}' not found" unless campaign

        campaign.assign_attributes(attrs.compact)
        save_record(campaign, campaign: campaign)
      end
    end
  end
end
