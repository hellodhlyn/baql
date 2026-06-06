# frozen_string_literal: true

module Sources
  class RaidScheduleByJpKey < GraphQL::Dataloader::Source
    def fetch(keys)
      present_keys = keys.compact
      raid_types = present_keys.map(&:first).uniq
      season_indexes = present_keys.map(&:second).uniq

      schedules = if present_keys.empty?
        {}
      else
        RaidSchedule
          .where(region: "jp", raid_type: raid_types, season_index: season_indexes)
          .index_by { |schedule| [schedule.raid_type, schedule.season_index] }
      end

      keys.map { |key| key ? schedules[key] : nil }
    end
  end
end
