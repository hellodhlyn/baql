module Queries
  class FurnituresQuery < Queries::BaseQuery
    type [Types::FurnitureType], null: false

    argument :uids, [String], required: false

    def resolve(uids: nil)
      return Furniture.order(:uid) if uids.nil?

      Furniture.where(uid: uids)
    end
  end
end
