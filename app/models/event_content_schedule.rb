class EventContentSchedule < ApplicationRecord
  belongs_to :event_content, foreign_key: :event_content_uid, primary_key: :uid

  validates :region, inclusion: { in: Constants::REGIONS }
  validates :run_type, inclusion: { in: Constants::EVENT_SCHEDULE_RUN_TYPES }
  validates :event_content_uid, uniqueness: { scope: [:region, :run_type] }
end
