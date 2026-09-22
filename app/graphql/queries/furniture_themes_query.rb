# frozen_string_literal: true

module Queries
  class FurnitureThemesQuery < Queries::BaseQuery
    type [Types::FurnitureThemeType], null: false

    def resolve
      ensure_catalog_ready!
      FurnitureTheme.order(:uid)
    end

    private

    def ensure_catalog_ready!
      return if FurnitureCatalogState.current&.ready?

      raise GraphQL::ExecutionError, "Furniture catalog is not ready"
    end
  end
end
