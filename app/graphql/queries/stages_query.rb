module Queries
  class StagesQuery < Queries::BaseQuery
    type [Types::StageType], null: false

    argument :uids, [String], required: false
    argument :category, String, required: false

    def resolve(uids: nil, category: nil)
      stages = Stage.order(:uid)
      stages = stages.where(uid: uids) if uids
      stages = stages.where(category: category) if category
      stages
    end
  end
end
