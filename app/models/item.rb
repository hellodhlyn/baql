class Item
  attr_accessor :item_id, :name, :image_id, :event_bonuses

  EventBonus = Data.define(:student_id, :ratio) do |data|
    def student = Student.find_by_student_id(student_id)
  end

  def self.find_by_item_id(item_id)
    raw_items = Rails.cache.fetch("data::items::all", expires_in: 1.hour) do
      SchaleDB::Data.items
    end

    Rails.cache.fetch("data::items::#{item_id}", expires_in: 1.minute) do
      raw_item = raw_items.find { |item| item["Id"].to_s == item_id.to_s }
      return nil if raw_item.nil?

      Item.new.tap do |item|
        item.item_id = raw_item["Id"].to_s
        item.name = raw_item["Name"]
        item.image_id = raw_item["Icon"]
        item.event_bonuses = raw_item["EventBonus"]&.map do |student_id, ratio_raw|
          EventBonus.new(student_id.to_s, ratio_raw.to_f / 10000)
        end || []
      end
    end
  end
end
