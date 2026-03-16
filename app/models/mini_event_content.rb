class MiniEventContent < ApplicationRecord
  include Translatable

  has_many :schedules, class_name: "MiniEventContentSchedule", foreign_key: :mini_event_content_uid, primary_key: :uid

  validates :uid,     presence: true, uniqueness: true
  validates :baql_id, presence: true

  BAQL_ID_PREFIX = "baql::mini_events::"

  translatable :name

  after_save :sync_translations!

  def translation_key_prefix
    baql_id
  end

  private

  def sync_translations!
    Constants::LANGUAGE_MAP.each do |data_path, lang|
      localization_data = SchaleDB::V1::Data.localization(data_path)
      event_names = localization_data["EventName"] || {}
      name = event_names[uid] || event_names[uid.to_i.to_s]
      set_name(name, lang) if name
    end
  end
end
