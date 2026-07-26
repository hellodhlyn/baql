class StudentSkill < ApplicationRecord
  TYPES = %w[ex public passive extra_passive].freeze
  TYPE_ORDER = TYPES.each_with_index.to_h.freeze

  belongs_to :student, primary_key: :uid, foreign_key: :student_uid

  before_validation :assign_legacy_uid

  validates :uid, presence: true
  validates :skill_type, presence: true, inclusion: { in: TYPES }
  validates :name, presence: true

  def name(lang = Constants::DEFAULT_LANGUAGE)
    localizations.dig(lang.to_s, "name").presence || read_attribute(:name)
  end

  def description(lang = Constants::DEFAULT_LANGUAGE)
    localizations.dig(lang.to_s, "description") ||
      localizations.dig(Constants::DEFAULT_LANGUAGE, "description")
  end

  private

  def assign_legacy_uid
    self.uid = "legacy:#{skill_type}" if uid.blank? && skill_type.present?
  end
end
