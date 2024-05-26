class Event < ApplicationRecord
  self.inheritance_column = :_type_disabled

  Pickup = Data.define(:type, :rerun, :student_id)
  Video  = Data.define(:title, :youtube, :start)

  json_array_attr :pickups, Pickup
  json_array_attr :videos, Video, default: { start: nil }
end
