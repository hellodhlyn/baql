class Raid < ApplicationRecord
  include ::Battleable

  self.inheritance_column = :_type_disabled

  RAID_TYPES   = ["total_assault", "elimination", "unlimit"]
  DIFFICULTIES = ["normal", "hard", "very_hard", "hardcore", "extreme", "insane", "torment", "lunatic"]

  validates :type, inclusion: { in: RAID_TYPES }

  scope :ongoing, -> { where("since <= ? AND until >= ?", Time.zone.now, Time.zone.now) }
  scope :upcoming, -> { where("since > ?", Time.zone.now) }
  scope :past, -> { where("until < ?", Time.zone.now) }

  ### Defense types
  DefenseType = Data.define(:defense_type, :difficulty)

  json_array_attr :defense_types, DefenseType
end
