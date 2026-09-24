# frozen_string_literal: true

module Queries
  class FurnituresQuery < Queries::BaseQuery
    type [Types::FurnitureType], null: false

    argument :uids, [String], required: false

    def resolve(uids: nil)
      ensure_catalog_ready!
      furnitures = Furniture.where(in_catalog: true).order(:uid)
      return furnitures if uids.nil?

      furnitures.where(uid: uids)
    end

    private

    def ensure_catalog_ready!
      return if FurnitureCatalogState.current&.ready?

      raise GraphQL::ExecutionError, "Furniture catalog is not ready"
    end
  end
end
