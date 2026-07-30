class EventContentRunBonus < ApplicationRecord
  self.table_name = "event_content_run_bonuses"

  belongs_to :event_content_run

  def as_payload
    {
      "student_uid" => student_uid,
      "reward_uid" => reward_uid,
      "reward_type" => reward_type,
      "percentage" => percentage,
    }
  end
end
