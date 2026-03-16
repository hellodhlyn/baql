# frozen_string_literal: true

module Types
  class CampaignType < Types::Base::Object
    class CategoryEnum < Types::Base::Enum
      Campaign::CATEGORIES.each { |c| value c, value: c }
    end

    field :uid,        String,                          null: false
    field :region,     String,                          null: false
    field :category,   [CategoryEnum],                  null: false
    field :multiplier, Integer,                         null: false
    field :start_at,   GraphQL::Types::ISO8601DateTime, null: false
    field :end_at,     GraphQL::Types::ISO8601DateTime, null: false
  end
end
