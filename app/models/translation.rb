class Translation < ApplicationRecord
  validates :language, presence: true, inclusion: { in: Constants::LANGUAGES }
  validates :key, presence: true, uniqueness: { scope: :language }
  validates :value, presence: true

  scope :by_language, ->(lang) { where(language: lang) }
end
