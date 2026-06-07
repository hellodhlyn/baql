# frozen_string_literal: true

module Queries
  class MiniStoryQuery < Queries::BaseQuery
    type Types::MiniStoryType, null: true

    argument :uid, String, required: true

    def resolve(uid:)
      MiniStory.find_by(uid: uid)
    end
  end
end
