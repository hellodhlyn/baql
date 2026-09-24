class Furniture < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::furnitures::"

  belongs_to :theme, class_name: "FurnitureTheme", foreign_key: :theme_uid, primary_key: :uid,
    inverse_of: :furnitures, optional: true

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
