# frozen_string_literal: true

module Mutations
  module MainStoryParts
    class UpdateMainStoryPart < Mutations::BaseMutation
      argument :uid,           String,                           required: true
      argument :chapter_uid,   String,                           required: false
      argument :sort_order,    Integer,                          required: false
      argument :episode_start, Integer,                          required: false
      argument :episode_end,   Integer,                          required: false
      argument :name,          [Types::Inputs::TranslationInput], required: false

      field :main_story_part, "Types::MainStoryPartType", null: true

      def resolve(uid:, name: nil, **attrs)
        part = find_record!(MainStoryPart, uid: uid)

        ActiveRecord::Base.transaction do
          part.assign_attributes(attrs.compact)
          part.save!
          name&.each { |translation| part.set_name(translation.value, translation.language) }
        end

        { main_story_part: part.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { main_story_part: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
