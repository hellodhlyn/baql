module Queries
  class ContentsQuery < Queries::BaseQuery
    type Types::ContentInterface.connection_type, null: false

    argument :until_after,  GraphQL::Types::ISO8601DateTime, required: false
    argument :since_before, GraphQL::Types::ISO8601DateTime, required: false
    argument :content_ids,  [String], required: false

    def resolve(until_after: nil, since_before: nil, content_ids: nil)
      [Event, Raid].map do |model|
        result = model == Event ? model.includes(:pickups, pickups: :student) : model
        result = result.order(since: :asc, until: :asc)
        result = result.where("until >= ?", until_after) if until_after.present?
        result = result.where("since < ?", since_before) if since_before.present?
        if content_ids.present?
          content_id_key = model.name.underscore + "_id"
          result = result.where(**{content_id_key => content_ids})
        end
        result
      end.flatten.sort_by do |content|
        [content.since, content.until]
      end
    end
  end
end
