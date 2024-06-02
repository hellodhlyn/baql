class Raid < ApplicationRecord
  include ::Battleable

  self.inheritance_column = :_type_disabled

  RAID_TYPES = ["total_assault", "elimination", "unlimit"]
  TERRAINS   = ["indoor", "outdoor", "street"]

  validates :type, inclusion: { in: RAID_TYPES }
end
