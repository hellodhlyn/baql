class FurnitureTheme < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::furniture_themes::"

  has_many :furnitures, foreign_key: :theme_uid, primary_key: :uid, inverse_of: :theme, dependent: :nullify
  has_many :template_previews, class_name: "FurnitureTemplatePreview", foreign_key: :furniture_theme_uid,
    primary_key: :uid, inverse_of: :furniture_theme, dependent: :delete_all

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
