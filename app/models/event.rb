class Event < ApplicationRecord
  self.inheritance_column = :_type_disabled

  EVENT_TYPES = [
    "event", "mini_event", "guide_mission", "immortal_event",
    "pickup", "fes", "campaign", "exercise", "main_story", "collab",
  ].freeze
  PICKUP_TYPES = ["usual", "limited", "given", "fes"].freeze

  validates :type, inclusion: { in: EVENT_TYPES }

  ### Video contents
  Video = Data.define(:title, :youtube, :start)

  json_array_attr :videos, Video, default: { start: nil }

  ### Pickup students
  Pickup = Data.define(:type, :rerun, :student, :fallback_student_name) do
    def student_name = student&.name || fallback_student_name
    def student_id   = student&.student_id
  end

  def pickups
    Rails.cache.fetch("data::events::#{id}::pickups", expires_in: 1.hour) do
      db_pickups = read_attribute(:pickups)
      return [] if db_pickups.nil?

      students = Student.where(student_id: db_pickups.map { |pickup| pickup["studentId"] }).index_by(&:student_id)
      db_pickups.map do |pickup|
        student = students[pickup["studentId"]]
        Pickup.new(pickup["type"], pickup["rerun"], student, pickup["studentName"])
      end
    end
  end

  ### Event stages
  Stage = Data.define(:name, :difficulty, :index, :entry_ap, :rewards)
  StageReward = Data.define(:item, :amount)

  def stages
    Rails.cache.fetch("data::events::#{id}::stages", expires_in: 1.hour) do
      items = {}

      event_stages = SchaleDB::V1::Data.events["Stages"].select { |id, stage| stage["EventId"] == event_index }.values
      event_stages.map do |stage|
        rewards = stage["Rewards"]["Jp"].select do |reward|
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
