class Resources::Furniture < Resource
  include ImageSyncable

  validates :uid, presence: true, uniqueness: true

  def self.sync!
    raw_furnitures = SchaleDB::V1::Data.furnitures
    raw_furnitures.each do |uid, raw_furniture|
      furniture = Resources::Furniture.find_or_initialize_by(uid: uid)
      furniture.update!(
        name: raw_furniture["Name"],
        category: raw_furniture["Category"].underscore,
        sub_category: raw_furniture["SubCategory"]&.underscore,
        rarity: case raw_furniture["Rarity"]
          when "N" then 1
          when "R" then 2
          when "SR" then 3
          when "SSR" then 4
          else raise "unknown rarity value: #{raw_furniture["Rarity"].inspect} for furniture #{uid}"
        end,
      )

      if furniture.saved_changes?
        Rails.logger.info("Furniture #{furniture.name}(#{furniture.uid}) has been updated")
        sync_image!("assets/images/furnitures/#{furniture.uid}", SchaleDB::V1::Images.furniture_icon(raw_furniture["Icon"]))
      end
    end

    nil
  end
end
