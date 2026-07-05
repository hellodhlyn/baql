# frozen_string_literal: true

module Mutations
  module MainStoryChapters
    class CreateMainStoryChapter < Mutations::BaseMutation
      argument :uid,            String,                           required: true
      argument :volume_uid,     String,                           required: true
      argument :chapter_number, Integer,                          required: true
      argument :name,           [Types::Inputs::TranslationInput], required: true

      field :main_story_chapter, "Types::MainStoryChapterType", null: true

      def resolve(uid:, volume_uid:, chapter_number:, name:)
        return { main_story_chapter: nil, errors: ["Name must include at least one translation"] } if name.blank?

        chapter = nil
        ActiveRecord::Base.transaction do
          chapter = MainStoryChapter.create!(
            uid: uid,
            baql_id: "#{MainStoryChapter::BAQL_ID_PREFIX}#{uid}",
            volume_uid: volume_uid,
            chapter_number: chapter_number,
          )
          name.each { |translation| chapter.set_name(translation.value, translation.language) }
        end

        { main_story_chapter: chapter.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { main_story_chapter: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
