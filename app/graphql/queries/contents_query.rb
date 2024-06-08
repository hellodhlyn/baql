module Queries
  class ContentsQuery < Queries::BaseQuery
    type Types::ContentInterface.connection_type, null: false

    argument :until_after,  GraphQL::Types::ISO8601DateTime, required: false
    argument :since_before, GraphQL::Types::ISO8601DateTime, required: false

    def resolve(until_after: nil, since_before: nil)
      [Event, Raid].map do |model|
        result = model.order(since: :asc, until: :asc)
        result = result.where("until >= ?", until_after) if until_after.present?
        result = result.where("since < ?", since_before) if since_before.present?
        result
      end.flatten.sort_by do |content|
        [content.since, content.until]
      end
    end
  end
end
