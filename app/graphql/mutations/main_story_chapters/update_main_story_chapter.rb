# frozen_string_literal: true

module Mutations
  module MainStoryChapters
    class UpdateMainStoryChapter < Mutations::BaseMutation
      argument :uid,            String,                           required: true
      argument :volume_uid,     String,                           required: false
      argument :chapter_number, Integer,                          required: false
      argument :name,           [Types::Inputs::TranslationInput], required: false

      field :main_story_chapter, "Types::MainStoryChapterType", null: true

      def resolve(uid:, name: nil, **attrs)
        chapter = find_record!(MainStoryChapter, uid: uid)

        ActiveRecord::Base.transaction do
          chapter.assign_attributes(attrs.compact)
          chapter.save!
          name&.each { |translation| chapter.set_name(translation.value, translation.language) }
        end

        { main_story_chapter: chapter.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { main_story_chapter: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
