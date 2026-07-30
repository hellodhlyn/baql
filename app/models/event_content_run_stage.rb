class EventContentRunStage < ApplicationRecord
  belongs_to :event_content_run
  has_many :rewards, -> { order(:position) }, class_name: "EventContentRunStageReward", dependent: :delete_all

  def as_payload
    {
      "uid" => uid,
      "stage_type" => stage_type,
      "stage_index" => stage_index,
      "stage_number" => stage_number,
      "enter_cost_type" => enter_cost_type,
      "enter_cost_uid" => enter_cost_uid,
      "enter_cost_amount" => enter_cost_amount,
      "rewards" => rewards.map(&:as_payload),
    }
  end
end
