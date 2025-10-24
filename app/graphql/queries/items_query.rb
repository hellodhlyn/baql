module Queries
  class ItemsQuery < Queries::BaseQuery
    type [Types::ItemType], null: false

    argument :uids, [String], required: false

    def resolve(uids: [])
      Resources::Item.where(uid: uids)
    end
  end
end
