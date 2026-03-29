# frozen_string_literal: true

module Mutations
  module RaidBosses
    class UpdateRaidBoss < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :raid_type, Types::Enums::BossTypeEnum, required: false
      argument :event_content_uid, String, required: false

      field :raid_boss, Types::RaidBossType, null: true

      def resolve(uid:, **attrs)
        if attrs[:event_content_uid].present? && !EventContent.exists?(uid: attrs[:event_content_uid])
          raise GraphQL::ExecutionError, "EventContent with uid '#{attrs[:event_content_uid]}' not found"
        end

        boss = find_record!(RaidBoss, uid: uid)
        boss.assign_attributes(attrs.compact)
        save_record(boss, raid_boss: boss)
      end
    end
  end
end
