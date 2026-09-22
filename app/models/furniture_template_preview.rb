class FurnitureTemplatePreview < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::furniture_template_previews::"

  belongs_to :furniture_theme, foreign_key: :furniture_theme_uid, primary_key: :uid,
    inverse_of: :template_previews

  validates :uid, presence: true, uniqueness: true
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  translatable :name

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
