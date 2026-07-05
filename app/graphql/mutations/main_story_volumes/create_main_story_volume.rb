# frozen_string_literal: true

module Mutations
  module MainStoryVolumes
    class CreateMainStoryVolume < Mutations::BaseMutation
      argument :uid,        String,                           required: true
      argument :season,     Integer,                          required: true
      argument :label,      String,                           required: true
      argument :sort_order, Integer,                          required: true
      argument :name,       [Types::Inputs::TranslationInput], required: true

      field :main_story_volume, Types::MainStoryVolumeType, null: true

      def resolve(uid:, season:, label:, sort_order:, name:)
        return { main_story_volume: nil, errors: ["Name must include at least one translation"] } if name.blank?

        volume = nil
        ActiveRecord::Base.transaction do
          volume = MainStoryVolume.create!(
            uid: uid,
            baql_id: "#{MainStoryVolume::BAQL_ID_PREFIX}#{uid}",
            season: season,
            label: label,
            sort_order: sort_order,
          )
          name.each { |translation| volume.set_name(translation.value, translation.language) }
        end

        { main_story_volume: volume.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { main_story_volume: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
