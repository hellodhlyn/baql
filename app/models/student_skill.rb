class StudentSkill < ApplicationRecord
  TYPES = %w[ex public passive extra_passive].freeze
  TYPE_ORDER = TYPES.each_with_index.to_h.freeze

  belongs_to :student, primary_key: :uid, foreign_key: :student_uid

  validates :skill_type, presence: true, inclusion: { in: TYPES }
  validates :name, presence: true
end
