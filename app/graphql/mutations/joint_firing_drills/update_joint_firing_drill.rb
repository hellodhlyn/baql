# frozen_string_literal: true

module Mutations
  module JointFiringDrills
    class UpdateJointFiringDrill < Mutations::BaseMutation
      argument :uid,          String,                                    required: true
      argument :season,       Integer,                                   required: false
      argument :drill_type,   Types::JointFiringDrillType::DrillTypeEnum, required: false
      argument :terrain,      Types::Enums::TerrainType,                 required: false
      argument :defense_type, Types::Enums::DefenseType,                 required: false
      argument :confirmed,    Boolean,                                   required: false

      field :joint_firing_drill, Types::JointFiringDrillType, null: true

      def resolve(uid:, **attrs)
        drill = find_record!(JointFiringDrill, uid: uid)
        drill.assign_attributes(attrs.compact)
        save_record(drill, joint_firing_drill: drill)
      end
    end
  end
end
