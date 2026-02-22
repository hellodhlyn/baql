class EventContentSchedule < ApplicationRecord
  belongs_to :event_content

  validates :region, inclusion: { in: Constants::REGIONS }
  validates :run_type, inclusion: { in: Constants::EVENT_SCHEDULE_RUN_TYPES }
  validates :event_content_id, uniqueness: { scope: [:region, :run_type] }
end
