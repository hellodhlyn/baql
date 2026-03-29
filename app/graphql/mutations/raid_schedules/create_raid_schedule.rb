# frozen_string_literal: true

module Mutations
  module RaidSchedules
    class CreateRaidSchedule < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :raid_boss_uid, String, required: true
      argument :region, Types::Enums::RegionType, required: true
      argument :raid_type, Types::Enums::RaidScheduleTypeEnum, required: true
      argument :season_index, Integer, required: true
      argument :terrain, Types::Enums::TerrainType, required: true
      argument :start_at, GraphQL::Types::ISO8601DateTime, required: false
      argument :end_at, GraphQL::Types::ISO8601DateTime, required: false
      argument :attack_type, Types::Enums::AttackType, required: false
      argument :defense_types, [Types::Inputs::DefenseTypeInput], required: false
      argument :jp_season_index, Integer, required: false
      argument :event_content_run_type, Types::Enums::EventScheduleRunTypeEnum, required: false

      field :raid_schedule, Types::RaidScheduleType, null: true

      def resolve(uid:, defense_types: [], **attrs)
        defense_types_data = defense_types.map { |dt| { "defense_type" => dt.defense_type, "difficulty" => dt.difficulty } }
        schedule = RaidSchedule.new(
          **attrs,
          uid: uid,
          baql_id: "#{RaidSchedule::BAQL_ID_PREFIX}#{uid}",
          defense_types: defense_types_data,
        )
        save_record(schedule, raid_schedule: schedule)
      end
    end
  end
end
