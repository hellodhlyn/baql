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
          item = items[reward["Id"]] ||= Item.find_by_item_id(reward["Id"].to_s, rerun_event: rerun)
          StageReward.new(item, reward["Amount"])
        end
        entry_ap = stage["EntryCost"]&.find { |item_id, _| item_id == 5 }&.last || nil
        Stage.new(stage["Name"], stage["Difficulty"], stage["Stage"].to_s, entry_ap, rewards)
      end
    end
  end
end
