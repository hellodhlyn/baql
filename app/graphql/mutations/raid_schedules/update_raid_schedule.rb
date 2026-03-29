# frozen_string_literal: true

module Mutations
  module RaidSchedules
    class UpdateRaidSchedule < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :raid_boss_uid, String, required: false
      argument :region, Types::Enums::RegionType, required: false
      argument :raid_type, Types::Enums::RaidScheduleTypeEnum, required: false
      argument :season_index, Integer, required: false
      argument :terrain, Types::Enums::TerrainType, required: false
      argument :start_at, GraphQL::Types::ISO8601DateTime, required: false
      argument :end_at, GraphQL::Types::ISO8601DateTime, required: false
      argument :attack_type, Types::Enums::AttackType, required: false
      argument :defense_types, [Types::Inputs::DefenseTypeInput], required: false
      argument :jp_season_index, Integer, required: false
      argument :event_content_run_type, Types::Enums::EventScheduleRunTypeEnum, required: false

      field :raid_schedule, Types::RaidScheduleType, null: true

      def resolve(uid:, defense_types: nil, **attrs)
        schedule = find_record!(RaidSchedule, uid: uid)
        schedule.assign_attributes(attrs.compact)
        if defense_types
          schedule.defense_types = defense_types.map { |dt| { "defense_type" => dt.defense_type, "difficulty" => dt.difficulty } }
        end
        save_record(schedule, raid_schedule: schedule)
      end
    end
  end
end
