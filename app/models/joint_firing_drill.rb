class JointFiringDrill < ApplicationRecord
  include ::Battleable

  DRILL_TYPES = ["shooting", "defense", "assault", "escort"].freeze

  has_many :schedules,
           class_name:  "JointFiringDrillSchedule",
           primary_key: :uid,
           foreign_key: :drill_uid,
           inverse_of:  :drill

  validates :uid,          presence: true, uniqueness: true
  validates :season,       uniqueness: true
  validates :drill_type,   inclusion: { in: DRILL_TYPES }
  validates :terrain,      inclusion: { in: TERRAINS }
  validates :defense_type, inclusion: { in: DEFENSE_TYPES }
end
