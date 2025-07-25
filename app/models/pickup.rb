class Pickup < ApplicationRecord
  PICKUP_TYPES = ["usual", "limited", "given", "fes", "archive"].freeze

  belongs_to :event, primary_key: :uid, foreign_key: :event_uid
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid, optional: true

  before_validation :fill_student, on: :create
  validates :pickup_type, inclusion: { in: PICKUP_TYPES }

  alias_attribute :type, :pickup_type

  def student_name = student&.name || fallback_student_name

  private

  def fill_student
    return if student.present?
    return if fallback_student_name.blank?

    self.student = Student.find_by(name: fallback_student_name)
  end
end
