class Event < ApplicationRecord
  self.inheritance_column = :_type_disabled

  EVENT_TYPES = [
    "event", "mini_event", "guide_mission", "immortal_event",
    "pickup", "fes", "campaign", "exercise", "main_story", "collab",
  ].freeze
  PICKUP_TYPES = ["usual", "limited", "given", "fes"].freeze

  validates :type, inclusion: { in: EVENT_TYPES }

  Pickup = Data.define(:type, :rerun, :student_id, :student_name) do |data|
    def initialize(type:, rerun:, student_id: nil, student_name: nil)
      super
    end

    def student = Student.find_by_student_id(student_id)
    def student_name = student&.name || to_h[:student_name]
  end

  Video = Data.define(:title, :youtube, :start)

  json_array_attr :pickups, Pickup
  json_array_attr :videos, Video, default: { start: nil }
end
