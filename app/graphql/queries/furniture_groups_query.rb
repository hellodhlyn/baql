module Queries
  class FurnitureGroupsQuery < Queries::BaseQuery
    type [Types::FurnitureGroupType], null: false

    argument :uids, [String], required: false

    def resolve(uids: nil)
      return FurnitureGroup.order(:uid) if uids.nil?

      FurnitureGroup.where(uid: uids)
    end
  end
end
