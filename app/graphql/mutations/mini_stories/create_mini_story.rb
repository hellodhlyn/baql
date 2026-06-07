# frozen_string_literal: true

module Mutations
  module MiniStories
    class CreateMiniStory < Mutations::BaseMutation
      argument :uid,           String,                                  required: true
      argument :episode_count, Integer,                                 required: true
      argument :title,         [Types::Inputs::TranslationInput],        required: true
      argument :schedules,     [Types::Inputs::MiniStoryScheduleInput], required: false

      field :mini_story, Types::MiniStoryType, null: true

      def resolve(uid:, episode_count:, title:, schedules: [])
        return { mini_story: nil, errors: ["Title must include at least one translation"] } if title.blank?

        mini_story = nil
        ActiveRecord::Base.transaction do
          mini_story = MiniStory.create!(
            uid: uid,
            baql_id: "#{MiniStory::BAQL_ID_PREFIX}#{uid}",
            episode_count: episode_count,
          )

          title.each { |translation| mini_story.set_title(translation.value, translation.language) }
          schedules.each do |schedule|
            MiniStorySchedule.create!(
              mini_story_uid: mini_story.uid,
              region: schedule.region,
              released_at: schedule.released_at,
            )
          end
        end

        { mini_story: mini_story.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { mini_story: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
