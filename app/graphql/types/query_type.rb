# frozen_string_literal: true

module Types
  class QueryType < Types::Base::Object
    field :contents, resolver: Queries::ContentsQuery
    field :event, resolver: Queries::EventQuery
    field :events, resolver: Queries::EventsQuery
    field :raid, resolver: Queries::RaidQuery
    field :raids, resolver: Queries::RaidsQuery
    field :student, resolver: Queries::StudentQuery
    field :students, resolver: Queries::StudentsQuery
    field :items, resolver: Queries::ItemsQuery
  end
end
