class EventStage < ApplicationRecord
  belongs_to :event, primary_key: :uid, foreign_key: :event_uid

  has_many :rewards, class_name: "EventStageReward", primary_key: :uid, foreign_key: :stage_uid
end
