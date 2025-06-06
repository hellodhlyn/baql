class Pickup < ApplicationRecord
  PICKUP_TYPES = ["usual", "limited", "given", "fes"].freeze

  belongs_to :event, primary_key: :uid, foreign_key: :event_uid
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid, optional: true

  validates :pickup_type, inclusion: { in: PICKUP_TYPES }

  alias_attribute :type, :pickup_type

  def student_name = student&.name || fallback_student_name
end
