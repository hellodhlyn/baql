module Queries
  class GachaGroupQuery < Queries::BaseQuery
    type Types::GachaGroupType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      GachaGroup.find_by(uid: uid)
    end
  end
end
