# frozen_string_literal: true

module Queries
  class StudentCatalogQuery < Queries::BaseQuery
    type Types::StudentCatalogType, null: true

    def resolve
      StudentCatalog.canonical
    end
  end
end
