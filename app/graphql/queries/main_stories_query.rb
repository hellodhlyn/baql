module Queries
  class MainStoriesQuery < Queries::BaseQuery
    type [Types::MainStoryVolumeType], null: false

    def resolve
      MainStoryVolume.order(:sort_order)
    end
  end
end
