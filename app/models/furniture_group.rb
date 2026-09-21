class FurnitureGroup < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::furniture_groups::"

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  has_many :furnitures,
           class_name: "Furniture",
           primary_key: :uid,
           foreign_key: :furniture_group_uid

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
