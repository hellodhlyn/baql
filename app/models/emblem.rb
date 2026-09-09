class Emblem < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::emblems::"

  validates :uid, presence: true, uniqueness: true
  validate :image_asset_keys_are_localized_strings

  translatable :name, :description

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end

  private

  def image_asset_keys_are_localized_strings
    return if image_asset_keys.is_a?(Hash) && image_asset_keys.keys.all? { |key| Constants::LANGUAGES.include?(key) } &&
      image_asset_keys.values.all? { |value| value.is_a?(String) && value.present? }

    errors.add(:image_asset_keys, "must map supported languages to non-empty asset keys")
  end
end
