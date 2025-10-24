class Resources::Equipment < Resource
  include ImageSyncable

  validates :uid, presence: true, uniqueness: true

  def self.sync!
    raw_equipments = SchaleDB::V1::Data.equipments
    raw_equipments.each do |uid, raw_equipment|
      equipment = Resources::Equipment.find_or_initialize_by(uid: uid)
      equipment.update!(
        name: raw_equipment["Name"],
        category: raw_equipment["Category"].underscore,
        sub_category: raw_equipment["SubCategory"]&.underscore,
        rarity: case raw_equipment["Rarity"]
          when "N" then 1
          when "R" then 2
          when "SR" then 3
          when "SSR" then 4
          else raise "unknown rarity value: #{raw_equipment["Rarity"].inspect} for equipment #{uid}"
        end,
      )

      if equipment.saved_changes?
        Rails.logger.info("Equipment #{equipment.name}(#{equipment.uid}) has been updated")
        sync_image!("assets/images/equipments/#{equipment.uid}", SchaleDB::V1::Images.equipment_icon(raw_equipment["Icon"]))
      end
    end

    nil
  end
end
