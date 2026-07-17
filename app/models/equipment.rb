class Equipment < ApplicationRecord
  self.table_name = "equipments"

  include Translatable

  BAQL_ID_PREFIX = "baql::equipments::"

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
