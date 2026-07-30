class EventContentRunStageReward < ApplicationRecord
  belongs_to :event_content_run_stage

  def as_payload
    {
      "reward_uid" => reward_uid,
      "reward_type" => reward_type,
      "amount" => amount,
      "probability" => probability.to_s("F"),
      "tag" => tag,
    }
  end
end
