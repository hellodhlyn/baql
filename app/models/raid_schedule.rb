class RaidSchedule < ApplicationRecord
  include Battleable

  BAQL_ID_PREFIX = "baql::raid_schedules::"
  RAID_TYPES = %w[total_assault elimination unlimit allied].freeze

  belongs_to :raid_boss, foreign_key: :raid_boss_uid, primary_key: :uid

  def jp_schedule
    return nil unless jp_season_index
    RaidSchedule.find_by(region: "jp", raid_type: raid_type, season_index: jp_season_index)
  end

  def event_content_schedule
    return nil unless event_content_run_type
    EventContentSchedule.find_by(event_content_uid: raid_boss.event_content_uid, region: region, run_type: event_content_run_type)
  end

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :region, inclusion: { in: Constants::REGIONS }
  validates :raid_type, inclusion: { in: RAID_TYPES }
  validates :season_index, uniqueness: { scope: [:region, :raid_type] }

  scope :ongoing,  -> { where("start_at <= ? AND end_at >= ?", Time.zone.now, Time.zone.now) }
  scope :upcoming, -> { where("start_at > ? OR start_at IS NULL", Time.zone.now) }
  scope :past,     -> { where("end_at < ?", Time.zone.now) }

  DefenseType = Data.define(:defense_type, :difficulty)
  json_array_attr :defense_types, DefenseType

  def assign_dates_from_event_content_schedule!
    ecs = event_content_schedule
    raise ArgumentError, "event_content_schedule is not resolvable" unless ecs
    update!(start_at: ecs.start_at, end_at: ecs.end_at)
  end

  def videos
    video_boss_name = RaidBoss::VIDEO_BOSS_NAME_OVERRIDES.fetch(raid_boss_uid, raid_boss_uid)
    RaidVideo.where(raid_type: raid_type, raid_boss: video_boss_name, raid_terrain: terrain)
  end

  def duplicate!(new_region:, new_season_index:)
    new_uid = "#{new_region}_#{self.raid_type}_#{new_season_index}"
    RaidSchedule.create!(self.attributes
      .except("id", "uid", "baql_id", "region", "season_index", "jp_season_index", "start_at", "end_at", "created_at", "updated_at")
      .merge(
        uid:             new_uid,
        baql_id:         "#{BAQL_ID_PREFIX}#{new_uid}",
        region:          "gl",
        season_index:    new_season_index,
        jp_season_index: self.region == "jp" ? self.season_index : nil,
      )
    )
  end
end
