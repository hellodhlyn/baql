class Equipment < ApplicationRecord
  self.table_name = "equipments"

  include ImageSyncable
  include Translatable

  BAQL_ID_PREFIX = "baql::equipments::"

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def self.sync!
    raw_equipments = SchaleDB::V1::Data.equipments
    raw_equipments.each do |uid, raw_equipment|
      equipment = Equipment.find_or_initialize_by(uid: uid, baql_id: "#{BAQL_ID_PREFIX}#{uid}")
      equipment.update!(
        category:     raw_equipment["Category"].underscore,
        sub_category: raw_equipment["SubCategory"]&.underscore,
        rarity:       case raw_equipment["Rarity"]
          when "N"   then 1
          when "R"   then 2
          when "SR"  then 3
          when "SSR" then 4
          else raise "unknown rarity value: #{raw_equipment["Rarity"].inspect} for equipment #{uid}"
        end,
        raw_data:     raw_equipment,
      )

      if equipment.saved_changes?
        Rails.logger.info("Equipment #{raw_equipment["Name"]}(#{equipment.uid}) has been updated")
        sync_image!("assets/images/equipments/#{equipment.uid}", SchaleDB::V1::Images.equipment_icon(raw_equipment["Icon"]))
      end
    end

    Constants::LANGUAGE_MAP.each do |data_path, lang|
      SchaleDB::V1::Data.equipments(data_path).each do |uid, raw_equipment|
        equipment = Equipment.find_by(uid: uid)
        next unless equipment
        equipment.set_name(raw_equipment["Name"], lang)
        equipment.set_description(raw_equipment["Desc"], lang)
      end
    end

    nil
  end

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
