class Item < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::items::"

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def duplicate!(new_uid)
    new_uid = new_uid.to_s
    new_item = Item.find_or_initialize_by(uid: new_uid)
    new_item.update!(
      baql_id:      "#{BAQL_ID_PREFIX}#{new_uid}",
      category:     category,
      sub_category: sub_category,
      rarity:       rarity,
      raw_data:     raw_data,
    )

    Constants::LANGUAGES.each do |lang|
      %i[name description].each do |field|
        value = public_send(field, lang)
        next unless value
        new_item.public_send(:"set_#{field}", value, lang)
      end
    end

    new_item
  end

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
