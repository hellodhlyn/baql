# frozen_string_literal: true

module Types
  class QueryType < Types::Base::Object
    field :contents, resolver: Queries::ContentsQuery
    field :events, resolver: Queries::EventsQuery
    field :raids, resolver: Queries::RaidsQuery
  end
end
