class EventStageRewardBonus < ApplicationRecord
  self.table_name = "event_stage_reward_bonuses"

  belongs_to :reward_resource, polymorphic: true, primary_key: :uid, foreign_key: :reward_resource_uid
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid
end
