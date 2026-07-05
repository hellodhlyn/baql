# frozen_string_literal: true

module Mutations
  module MainStoryParts
    class CreateMainStoryPart < Mutations::BaseMutation
      argument :uid,           String,                           required: true
      argument :chapter_uid,   String,                           required: true
      argument :sort_order,    Integer,                          required: true
      argument :episode_start, Integer,                          required: false
      argument :episode_end,   Integer,                          required: false
      argument :name,          [Types::Inputs::TranslationInput], required: false

      field :main_story_part, "Types::MainStoryPartType", null: true

      def resolve(uid:, chapter_uid:, sort_order:, name: nil, episode_start: nil, episode_end: nil)
        part = nil
        ActiveRecord::Base.transaction do
          part = MainStoryPart.create!(
            uid: uid,
            baql_id: "#{MainStoryPart::BAQL_ID_PREFIX}#{uid}",
            chapter_uid: chapter_uid,
            sort_order: sort_order,
            episode_start: episode_start,
            episode_end: episode_end,
          )
          apply_name_translations(part, name)
        end

        { main_story_part: part.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { main_story_part: nil, errors: e.record.errors.full_messages }
      end

      private

      def apply_name_translations(part, translations)
        translations&.each do |translation|
          value = translation.value.presence
          next if value.nil?

          part.set_name(value, translation.language)
        end
      end
    end
  end
end
