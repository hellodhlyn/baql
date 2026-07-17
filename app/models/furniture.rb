class Furniture < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::furnitures::"

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
