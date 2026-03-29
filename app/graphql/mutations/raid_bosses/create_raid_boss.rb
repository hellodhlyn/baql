# frozen_string_literal: true

module Mutations
  module RaidBosses
    class CreateRaidBoss < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :raid_type, Types::Enums::BossTypeEnum, required: true
      argument :event_content_uid, String, required: false

      field :raid_boss, Types::RaidBossType, null: true

      def resolve(uid:, raid_type:, event_content_uid: nil)
        if event_content_uid.present? && !EventContent.exists?(uid: event_content_uid)
          raise GraphQL::ExecutionError, "EventContent with uid '#{event_content_uid}' not found"
        end

        boss = RaidBoss.new(
          uid: uid,
          baql_id: "#{RaidBoss::BAQL_ID_PREFIX}#{uid}",
          raid_type: raid_type,
          event_content_uid: event_content_uid,
        )
        save_record(boss, raid_boss: boss)
      end
    end
  end
end
