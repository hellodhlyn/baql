class EventStageReward < ApplicationRecord
  belongs_to :stage, class_name: "EventStage", primary_key: :uid, foreign_key: :stage_uid

  def item
    return nil unless reward_type == "item"
    Resources::Item.find_by(uid: reward_uid)
  end
end
