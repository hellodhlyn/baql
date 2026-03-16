class MainStoryPartSchedule < ApplicationRecord
  belongs_to :part, class_name: "MainStoryPart", foreign_key: :part_uid, primary_key: :uid

  validates :region, inclusion: { in: Constants::REGIONS }
  validates :part_uid, uniqueness: { scope: :region }
  validates :released_at, presence: true
end
