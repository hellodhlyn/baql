# frozen_string_literal: true

module Mutations
  module MainStoryVolumes
    class UpdateMainStoryVolume < Mutations::BaseMutation
      argument :uid,        String,                           required: true
      argument :season,     Integer,                          required: false
      argument :label,      String,                           required: false
      argument :sort_order, Integer,                          required: false
      argument :name,       [Types::Inputs::TranslationInput], required: false

      field :main_story_volume, Types::MainStoryVolumeType, null: true

      def resolve(uid:, name: nil, **attrs)
        volume = find_record!(MainStoryVolume, uid: uid)

        ActiveRecord::Base.transaction do
          volume.assign_attributes(attrs.compact)
          volume.save!
          name&.each { |translation| volume.set_name(translation.value, translation.language) }
        end

        { main_story_volume: volume.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { main_story_volume: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
