class Furniture < ApplicationRecord
  include ImageSyncable
  include Translatable

  BAQL_ID_PREFIX = "baql::furnitures::"

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def self.sync!
    raw_furnitures = SchaleDB::V1::Data.furnitures
    raw_furnitures.each do |uid, raw_furniture|
      furniture = Furniture.find_or_initialize_by(uid: uid, baql_id: "#{BAQL_ID_PREFIX}#{uid}")
      furniture.update!(
        category:     raw_furniture["Category"].underscore,
        sub_category: raw_furniture["SubCategory"]&.underscore,
        rarity:       case raw_furniture["Rarity"]
          when "N"   then 1
          when "R"   then 2
          when "SR"  then 3
          when "SSR" then 4
          else raise "unknown rarity value: #{raw_furniture["Rarity"].inspect} for furniture #{uid}"
        end,
        tags:         raw_furniture["Tags"] || [],
        raw_data:     raw_furniture,
      )

      if furniture.saved_changes?
        Rails.logger.info("Furniture #{raw_furniture["Name"]}(#{furniture.uid}) has been updated")
        sync_image!("assets/images/furnitures/#{furniture.uid}", SchaleDB::V1::Images.furniture_icon(raw_furniture["Icon"]))
      end
    end

    Constants::LANGUAGE_MAP.each do |data_path, lang|
      SchaleDB::V1::Data.furnitures(data_path).each do |uid, raw_furniture|
        furniture = Furniture.find_by(uid: uid)
        next unless furniture
        furniture.set_name(raw_furniture["Name"], lang)
        furniture.set_description(raw_furniture["Desc"], lang)
      end
    end

    nil
  end

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
