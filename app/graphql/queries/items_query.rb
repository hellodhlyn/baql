module Queries
  class ItemsQuery < Queries::BaseQuery
    type [Types::ItemType], null: false

    argument :uids, [String], required: false

    def resolve(uids: nil)
      return Item.order(:uid) if uids.nil?

      Item.where(uid: uids)
    end
  end
end
