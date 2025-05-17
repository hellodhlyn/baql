class Pickup < ApplicationRecord
  PICKUP_TYPES = ["usual", "limited", "given", "fes"].freeze

  # [FIXME v1] Rename `event_id` to `uid`
  belongs_to :event, primary_key: :event_id, foreign_key: :event_uid
  # [FIXME v1] Rename `student_id` to `uid`
  belongs_to :student, primary_key: :student_id, foreign_key: :student_uid, optional: true

  validates :pickup_type, inclusion: { in: PICKUP_TYPES }

  alias_attribute :type, :pickup_type

  def student_name = student&.name || fallback_student_name
end
