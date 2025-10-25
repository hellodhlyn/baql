class Event < ApplicationRecord
  self.inheritance_column = :_type_disabled

  EVENT_TYPES = [
    "event", "mini_event", "guide_mission", "immortal_event",
    "pickup", "archive_pickup", "fes", "campaign", "exercise", "main_story", "collab",
  ].freeze

  validates :type, inclusion: { in: EVENT_TYPES }

  has_many :pickups, primary_key: :uid, foreign_key: :event_uid

  ### Video contents
  Video = Data.define(:title, :youtube, :start)

  json_array_attr :videos, Video, default: { start: nil }

  ### Event stages
  Stage = Data.define(:name, :difficulty, :index, :entry_ap, :rewards)
  StageReward = Data.define(:item, :amount)

  def stages
    Rails.cache.fetch("data::events::#{id}::stages", expires_in: 10.minutes) do
      items = {}

      event_stages = SchaleDB::V1::Data.events["Stages"].select { |id, stage| stage["EventId"] == event_index }.values
      event_stages.map do |stage|
        rewards = stage["Rewards"].select do |reward|
          reward["Type"] == "Item" && (reward["Chance"].nil? || reward["Chance"] >= 1) && reward["RewardType"].nil?
        end.map do |reward|
          item = items[reward["Id"]] ||= find_legacy_item(reward["Id"].to_s, rerun_event: rerun)
          StageReward.new(item, reward["Amount"])
        end
        entry_ap = stage["EntryCost"]&.find { |item_id, _| item_id == 5 }&.last || nil
        Stage.new(stage["Name"], stage["Difficulty"], stage["Stage"].to_s, entry_ap, rewards)
      end
    end
  end
  alias_method :legacy_stages, :stages

  # @deprecated Use `Item` model instead
  EventBonus = Data.define(:student_uid, :ratio) do |data|
    def student = Student.find_by_uid(student_uid)
  end

  # @deprecated Use `Item` model instead
  def find_legacy_item(item_id, rerun_event: false)
    Rails.cache.fetch("data::items::#{item_id}", expires_in: 1.minute) do
      raw_items = Rails.cache.fetch("data::items::all_v1", expires_in: 1.hour) { SchaleDB::V1::Data.items }
      return nil unless raw_items.key?(item_id)

      raw_item = raw_items[item_id]
      event_bonus_key = rerun_event ? "EventBonusRerun" : "EventBonus"
      {
        item_id: raw_item["Id"].to_s,
        name: raw_item["Name"],
        image_id: raw_item["Icon"],
        event_bonuses: raw_item[event_bonus_key]&.[]("Jp")&.map do |student_uid, ratio_raw|
          EventBonus.new(student_uid.to_s, ratio_raw.to_f / 10000)
        end || [],
      }
    end
  end
end
