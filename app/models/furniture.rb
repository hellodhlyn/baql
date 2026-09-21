class Furniture < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::furnitures::"

  belongs_to :furniture_group,
             class_name: "FurnitureGroup",
             primary_key: :uid,
             foreign_key: :furniture_group_uid,
             optional: true

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
