# @deprecated Use `Resources::Item` model instead
class Item < ApplicationRecord
  validates :uid, presence: true, uniqueness: true
end
