class MiniEventContentSchedule < ApplicationRecord
  belongs_to :mini_event_content, foreign_key: :mini_event_content_uid, primary_key: :uid

  validates :region,     inclusion: { in: Constants::REGIONS }
  validates :occurrence, numericality: { only_integer: true, greater_than: 0 }
  validates :mini_event_content_uid, uniqueness: { scope: [:region, :occurrence] }
end
