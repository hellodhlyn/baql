class EventContent < ApplicationRecord
  include Translatable
  include ImageSyncable

  has_many :schedules, class_name: "EventContentSchedule", foreign_key: :event_content_uid, primary_key: :uid
  has_many :event_content_runs, primary_key: :uid, foreign_key: :event_content_uid, dependent: :delete_all

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true

  BAQL_ID_PREFIX = "baql::events::"
  RUN_TYPE_MAP = {
    "Original" => "first",
    "Rerun" => "rerun",
    "Permanent" => "permanent",
  }.freeze
  RUN_TYPE_FALLBACK = { "permanent" => "first" }.freeze
  LOGO_LOCALES = %w[Jp Kr].freeze
  SCHALE_DB_SCHEDULE_REGION_MAP = {
    "Global" => "gl",
    "Cn" => "cn",
  }.freeze

  translatable :name

  def self.sync!
    events = SchaleDB::V1::Data.events["Events"] || []
    events.each do |event_data|
      event_id = event_data.fetch("Id").to_s
      event_content = find_or_initialize_by(uid: event_id, baql_id: "#{BAQL_ID_PREFIX}#{event_id}")
      needs_logo_sync = event_content.new_record? || !Translation.exists?(
        key: "#{event_content.translation_key_prefix}::name",
        language: "ja",
      )
      event_content.save!
      sync_event_logos!(event_content) if needs_logo_sync

      RUN_TYPE_MAP.each do |run_type_key, run_type|
        schedule_data = event_data[run_type_key]
        next unless schedule_data

        SCHALE_DB_SCHEDULE_REGION_MAP.each do |region_key, region|
          open_timestamp = schedule_data["EventOpen#{region_key}"]
          close_timestamp = schedule_data["EventClose#{region_key}"]
          next unless open_timestamp && close_timestamp

          start_at = timestamp_to_datetime(open_timestamp)
          next unless start_at

          event_content.schedules.find_or_initialize_by(region: region, run_type: run_type).update!(
            start_at: start_at,
            end_at: timestamp_to_datetime(close_timestamp),
          )
        end
      end
    end

    Constants::LANGUAGE_MAP.each do |data_path, lang|
      event_names = SchaleDB::V1::Data.localization(data_path)["EventName"] || {}
      event_names.each do |event_id, name|
        find_by(uid: event_id)&.set_name(name, lang)
      end
    end

    nil
  end

  def translation_key_prefix
    baql_id
  end

  def event_run(run_type)
    event_content_runs.find_by(run_type: mechanics_run_type(run_type))
  end

  def stages(run_type: "first")
    event_run(run_type)&.stages_payload || []
  end

  def bonuses(run_type: "first")
    event_run(run_type)&.bonuses_payload || []
  end

  def shop_resources(run_type: "first")
    event_run(run_type)&.shop_resources_payload || []
  end

  def minigame_configs(run_type: "first")
    event_run(run_type)&.minigame_configs_payload || []
  end

  def mechanics_run_type(run_type)
    RUN_TYPE_FALLBACK.fetch(run_type.to_s, run_type.to_s)
  end

  def self.sync_event_logos!(event_content)
    LOGO_LOCALES.each do |locale_suffix|
      image_body = SchaleDB::V1::Images.event_logo(event_content.uid, locale_suffix)
      next if image_body.blank?

      key = image_storage_key("events", "logo", "#{event_content.uid}_#{locale_suffix.downcase}.webp")
      sync_image!(key, image_body)
    end
  end

  def self.timestamp_to_datetime(timestamp)
    return nil if timestamp.nil? || timestamp >= 4102412400

    Time.zone.at(timestamp)
  end
end
