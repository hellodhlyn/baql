class Event < ApplicationRecord
  self.inheritance_column = :_type_disabled

  EVENT_TYPES = [
    "event", "mini_event", "guide_mission", "immortal_event",
    "pickup", "fes", "campaign", "exercise", "main_story", "collab",
    "update", "battle_pass",
  ].freeze

  validates :type, inclusion: { in: EVENT_TYPES }

  # @deprecated Use `recruitments` instead
  has_many :pickups, primary_key: :uid, foreign_key: :event_uid
  alias_method :recruitments, :pickups

  has_many :stages, class_name: "EventStage", primary_key: :uid, foreign_key: :event_uid

  scope :ongoing, -> { where("since <= ? AND until >= ?", Time.zone.now, Time.zone.now) }
  scope :upcoming, -> { where("since > ?", Time.zone.now) }
  scope :past, -> { where("until < ?", Time.zone.now) }

  ### Video contents
  Video = Data.define(:title, :youtube, :start)

  json_array_attr :videos, Video, default: { start: nil }

  def sync_stages!
    return nil unless self.type == "event" && self.event_index.present?

    raw_items = SchaleDB::V1::Data.items

    version = self.rerun ? "Rerun" : "Original"
    raw_stages = SchaleDB::V1::Data.events["Stages"].select { |_, stage| stage["EventId"] == self.event_index && stage["Versions"].include?(version) }.values
    raw_stages.each do |raw_stage|
      stage = EventStage.find_or_initialize_by(uid: raw_stage["Id"].to_s)
      stage.update!(
        event_uid:  self.uid,
        name:       raw_stage["Name"],
        difficulty: raw_stage["Difficulty"],
        index:      raw_stage["Stage"].to_s,
        entry_ap:   raw_stage["EntryCost"]&.find { |item_id, _| item_id == 5 }&.last || 0,
      )

      raw_stage["Rewards"].each do |raw_reward|
        reward = EventStageReward.find_or_initialize_by(stage: stage, reward_type: raw_reward["Type"].underscore, reward_uid: raw_reward["Id"].to_s, reward_requirement: raw_reward["RewardType"]&.underscore)
        reward.update!(
          amount:             raw_reward["Amount"],
          amount_min:         raw_reward["AmountMin"],
          amount_max:         raw_reward["AmountMax"],
          chance:             raw_reward["Chance"]&.to_d,
        )

        if reward.reward_type == "item"
          raw_item = raw_items[reward.reward_uid]
          raw_item[self.rerun ? "EventBonusRerun" : "EventBonus"]&.[]("Jp")&.each do |student_uid, ratio_raw|
            reward_resource = Resources::Item.find_by(uid: reward.reward_uid)
            next unless reward_resource

            bonus = EventStageRewardBonus.find_or_initialize_by(reward_resource: reward_resource, student_uid: student_uid.to_s)
            bonus.update!(ratio: ratio_raw.to_d / 10000)
          end
        end
      end
    end

    nil
  end
end
