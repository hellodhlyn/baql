# frozen_string_literal: true

module Queries
  class FurnitureThemeQuery < Queries::BaseQuery
    type Types::FurnitureThemeType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      state = FurnitureCatalogState.current
      raise GraphQL::ExecutionError, "Furniture catalog is not ready" unless state&.ready?

      FurnitureTheme.find_by(uid: uid)
    end
  end
end
