# frozen_string_literal: true

module Mutations
  module JointFiringDrills
    class CreateJointFiringDrill < Mutations::BaseMutation
      argument :uid,          String,                                    required: true
      argument :season,       Integer,                                   required: true
      argument :drill_type,   Types::JointFiringDrillType::DrillTypeEnum, required: true
      argument :terrain,      Types::Enums::TerrainType,                 required: true
      argument :defense_type, Types::Enums::DefenseType,                 required: true
      argument :confirmed,    Boolean,                                   required: false, default_value: true
      argument :schedules,    [Types::Inputs::JfdScheduleInput],         required: false

      field :joint_firing_drill, Types::JointFiringDrillType, null: true

      def resolve(uid:, season:, drill_type:, terrain:, defense_type:, confirmed:, schedules: [])
        drill = nil
        ActiveRecord::Base.transaction do
          drill = JointFiringDrill.create!(
            uid: uid,
            season: season,
            drill_type: drill_type,
            terrain: terrain,
            defense_type: defense_type,
            confirmed: confirmed,
          )
          schedules.each do |s|
            JointFiringDrillSchedule.create!(
              drill_uid: drill.uid,
              region: s.region,
              start_at: s.start_at,
              end_at: s.end_at,
            )
          end
        end
        { joint_firing_drill: drill.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { joint_firing_drill: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
