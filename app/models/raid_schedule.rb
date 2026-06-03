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
  DefenseTypeSet = Data.define(:defense_types, :difficulty)

  def defense_type_sets
    raw_defense_type_entries.map do |entry|
      DefenseTypeSet.new(
        defense_types: normalize_defense_type_entry(entry),
        difficulty: entry["difficulty"],
      )
    end
  end

  def defense_type_sets=(sets)
    self[:defense_types] = sets.map do |set|
      defense_types = normalize_defense_types_for_write(set)

      {
        "defense_types" => defense_types,
        "difficulty" => read_defense_type_value(set, :difficulty),
      }
    end
  end

  def defense_types
    defense_type_sets.flat_map do |set|
      set.defense_types.map do |defense_type|
        DefenseType.new(defense_type: defense_type, difficulty: set.difficulty)
      end
    end
  end

  # Legacy writer remains because existing rows and sync paths can still carry singleton raw JSON.
  def defense_types=(values)
    self[:defense_types] = values.map do |value|
      grouped = read_defense_type_value(value, :defense_types)
      if grouped
        defense_types = normalize_defense_types_for_write(value)

        next {
          "defense_types" => defense_types,
          "difficulty" => read_defense_type_value(value, :difficulty),
        }
      end

      {
        "defense_type" => read_defense_type_value(value, :defense_type),
        "difficulty" => read_defense_type_value(value, :difficulty),
      }
    end
  end

  def assign_dates_from_event_content_schedule!
    ecs = event_content_schedule
    raise ArgumentError, "event_content_schedule is not resolvable" unless ecs
    update!(start_at: ecs.start_at, end_at: ecs.end_at)
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

  private

  def raw_defense_type_entries
    Array(read_attribute(:defense_types))
  end

  def normalize_defense_type_entry(entry)
    grouped = entry["defense_types"] || entry[:defense_types]
    legacy = entry["defense_type"] || entry[:defense_type]
    Array(grouped || legacy).compact.map(&:to_s)
  end

  def normalize_defense_types_for_write(value)
    defense_types = Array(read_defense_type_value(value, :defense_types)).compact.map(&:to_s)
    raise ArgumentError, "defense_types must not be empty" if defense_types.empty?

    defense_types
  end

  def read_defense_type_value(value, key)
    return value.public_send(key) if value.respond_to?(key)
    return nil unless value.respond_to?(:[])

    value[key.to_s] || value[key]
  end
end
