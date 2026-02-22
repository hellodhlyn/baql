class EventContent < ApplicationRecord
  include Translatable

  has_many :schedules, class_name: "EventContentSchedule", dependent: :destroy

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true

  BAQL_ID_PREFIX = "baql::events::"

  RUN_TYPE_MAP = {
    "Original"  => "first",
    "Rerun"     => "rerun",
    "Permanent" => "permanent"
  }.freeze

  REGION_MAP = {
    "Jp"     => "jp",
    "Global" => "gl",
    "Cn"     => "cn"
  }.freeze

  translatable :name

  def self.sync!
    # 이벤트 일정 동기화
    events_data = SchaleDB::V1::Data.events
    events = events_data["Events"] || []

    events.each do |event_data|
      event_id = event_data["Id"].to_s
      event_content = find_or_initialize_by(uid: event_id, baql_id: "#{BAQL_ID_PREFIX}#{event_id}")
      event_content.save!

      # Original, Rerun, Permanent 각각 처리
      RUN_TYPE_MAP.each do |run_type_key, run_type|
        next unless event_data[run_type_key]

        schedule_data = event_data[run_type_key]

        # 각 서버별로 일정 upsert
        REGION_MAP.each do |region_key, region|
          open_timestamp = schedule_data["EventOpen#{region_key}"]
          close_timestamp = schedule_data["EventClose#{region_key}"]
          next unless open_timestamp && close_timestamp

          start_at = timestamp_to_datetime(open_timestamp)
          end_at = timestamp_to_datetime(close_timestamp)
          next unless start_at

          schedule = event_content.schedules.find_or_initialize_by(region: region, run_type: run_type)
          schedule.update!(start_at: start_at, end_at: end_at)
        end
      end
    end

    # 이벤트 이름 번역 동기화
    Constants::LANGUAGE_MAP.each do |data_path, lang|
      localization_data = SchaleDB::V1::Data.localization(data_path)
      event_names = localization_data["EventName"] || {}
      event_names.each do |event_id, name|
        event_content = find_by(uid: event_id)
        event_content&.set_name(name, lang)
      end
    end

    nil
  end

  def translation_key_prefix
    baql_id
  end

  private

  def self.timestamp_to_datetime(timestamp)
    return nil if timestamp.nil? || timestamp >= 4102412400
    Time.zone.at(timestamp)
  end
end
