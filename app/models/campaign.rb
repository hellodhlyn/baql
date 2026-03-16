# frozen_string_literal: true

class Campaign < ApplicationRecord
  CATEGORIES = %w[
    mission_normal mission_hard bounty_hunt commision
    schedule scrimmage exp
  ].freeze

  validates :region,     inclusion: { in: Constants::REGIONS }
  validates :multiplier, numericality: { only_integer: true, greater_than: 1 }
  validate  :validate_categories

  private

  def validate_categories
    return if category.is_a?(Array) && category.all? { |c| CATEGORIES.include?(c) }

    errors.add(:category, "contains invalid category")
  end
end
