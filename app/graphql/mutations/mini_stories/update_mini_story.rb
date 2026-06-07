# frozen_string_literal: true

module Mutations
  module MiniStories
    class UpdateMiniStory < Mutations::BaseMutation
      argument :uid,           String,                                  required: true
      argument :episode_count, Integer,                                 required: false
      argument :title,         [Types::Inputs::TranslationInput],        required: false
      argument :schedules,     [Types::Inputs::MiniStoryScheduleInput], required: false

      field :mini_story, Types::MiniStoryType, null: true

      def resolve(uid:, episode_count: nil, title: nil, schedules: nil)
        mini_story = find_record!(MiniStory, uid: uid)

        ActiveRecord::Base.transaction do
          mini_story.update!(episode_count: episode_count) unless episode_count.nil?
          title&.each { |translation| mini_story.set_title(translation.value, translation.language) }
          schedules&.each do |schedule|
            mini_story_schedule = MiniStorySchedule.find_or_initialize_by(
              mini_story_uid: mini_story.uid,
              region: schedule.region,
            )
            mini_story_schedule.update!(released_at: schedule.released_at)
          end
        end

        { mini_story: mini_story.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { mini_story: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
