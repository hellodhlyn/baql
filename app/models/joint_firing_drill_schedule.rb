class JointFiringDrillSchedule < ApplicationRecord
  belongs_to :drill,
             class_name:  "JointFiringDrill",
             primary_key: :uid,
             foreign_key: :drill_uid,
             inverse_of:  :schedules

  validates :region, inclusion: { in: Constants::REGIONS }
end
