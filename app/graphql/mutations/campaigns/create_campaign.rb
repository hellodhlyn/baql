# frozen_string_literal: true

module Mutations
  module Campaigns
    class CreateCampaign < Mutations::BaseMutation
      argument :uid,        String,                          required: true
      argument :region,     Types::Enums::RegionType,        required: true
      argument :category,   [Types::CampaignType::CategoryEnum], required: true
      argument :multiplier, Integer,                         required: true
      argument :start_at,   GraphQL::Types::ISO8601DateTime, required: true
      argument :end_at,     GraphQL::Types::ISO8601DateTime, required: true

      field :campaign, Types::CampaignType, null: true

      def resolve(uid:, region:, category:, multiplier:, start_at:, end_at:)
        campaign = Campaign.new(
          uid: uid,
          region: region,
          category: category,
          multiplier: multiplier,
          start_at: start_at,
          end_at: end_at,
        )
        save_record(campaign, campaign: campaign)
      end
    end
  end
end
