class Item
  attr_accessor :item_id, :name, :image_id, :event_bonuses

  EventBonus = Data.define(:student_uid, :ratio) do |data|
    def student = Student.find_by_uid(student_uid)
  end

  def self.find_by_item_id(item_id, rerun_event: false)
    Rails.cache.fetch("data::items::#{item_id}", expires_in: 1.minute) do
      raw_items = Rails.cache.fetch("data::items::all_v1", expires_in: 1.hour) { SchaleDB::V1::Data.items }
      return nil unless raw_items.key?(item_id)

      raw_item = raw_items[item_id]
      Item.new.tap do |item|
        item.item_id = raw_item["Id"].to_s
        item.name = raw_item["Name"]
        item.image_id = raw_item["Icon"]

        event_bonus_key = rerun_event ? "EventBonusRerun" : "EventBonus"
        item.event_bonuses = raw_item[event_bonus_key]&.[]("Jp")&.map do |student_uid, ratio_raw|
          EventBonus.new(student_uid.to_s, ratio_raw.to_f / 10000)
        end || []
      end
    end
  end
end
