class Item < ApplicationRecord
  include ImageSyncable

  validates :uid, presence: true, uniqueness: true

  def self.sync!
    raw_items = SchaleDB::V1::Data.items
    raw_items.each do |uid, raw_item|
      item = Item.find_or_initialize_by(uid: uid)
      item.update!(
        name: raw_item["Name"],
        category: raw_item["Category"].downcase,
        sub_category: raw_item["SubCategory"]&.downcase,
        rarity: case raw_item["Rarity"]
          when "N" then 1
          when "R" then 2
          when "SR" then 3
          when "SSR" then 4
          else raise "unknown rarity value: #{raw_item["Rarity"].inspect} for item #{uid}"
        end,
      )

      if item.saved_changes?
        Rails.logger.info("Item #{item.name}(#{item.uid}) has been updated")
        sync_image!("assets/images/items/#{item.uid}", SchaleDB::V1::Images.item_icon(raw_item["Icon"]))
      end
    end
  end
end
