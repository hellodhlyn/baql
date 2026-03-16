class Item < ApplicationRecord
  include ImageSyncable
  include Translatable

  BAQL_ID_PREFIX = "baql::items::"

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def self.sync!
    # 1) kr 기준으로 카테고리/레어도 등 메타 데이터 sync
    raw_items = SchaleDB::V1::Data.items
    raw_items.each do |uid, raw_item|
      item = Item.find_or_initialize_by(uid: uid, baql_id: "#{BAQL_ID_PREFIX}#{uid}")
      item.update!(
        category:     raw_item["Category"].underscore,
        sub_category: raw_item["SubCategory"]&.underscore,
        rarity:       case raw_item["Rarity"]
          when "N"   then 1
          when "R"   then 2
          when "SR"  then 3
          when "SSR" then 4
          else raise "unknown rarity value: #{raw_item["Rarity"].inspect} for item #{uid}"
        end,
        raw_data:     raw_item,
      )

      if item.saved_changes?
        Rails.logger.info("Item #{raw_item["Name"]}(#{item.uid}) has been updated")
        sync_image!("assets/images/items/#{item.uid}", SchaleDB::V1::Images.item_icon(raw_item["Icon"]))
      end
    end

    # 2) 언어별 이름 & 설명 Translation 저장
    Constants::LANGUAGE_MAP.each do |data_path, lang|
      SchaleDB::V1::Data.items(data_path).each do |uid, raw_item|
        item = Item.find_by(uid: uid)
        next unless item
        item.set_name(raw_item["Name"], lang)
        item.set_description(raw_item["Desc"], lang)
      end
    end

    nil
  end

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

    self.class.copy_image!("assets/images/items/#{uid}", "assets/images/items/#{new_uid}")

    new_item
  end

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
