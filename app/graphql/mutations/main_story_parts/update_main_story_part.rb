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
          apply_name_translations(part, name)
        end

        { main_story_part: part.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { main_story_part: nil, errors: e.record.errors.full_messages }
      end

      private

      def apply_name_translations(part, translations)
        translations&.each do |translation|
          key = "#{part.translation_key_prefix}::name"
          value = translation.value.presence

          if value
            part.set_name(value, translation.language)
          else
            Translation.find_by(key: key, language: translation.language)&.destroy!
          end
        end
      end
    end
  end
end
