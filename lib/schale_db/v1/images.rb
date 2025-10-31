module SchaleDB::V1
  class Images
    HOST = "https://schaledb.com"

    def self.student_collection(student_uid)
      get("images/student/collection/#{student_uid}.webp")
    end

    def self.student_standing(student_uid)
      get("images/student/portrait/#{student_uid}.webp")
    end

    def self.item_icon(item_id)
      get("images/item/icon/#{item_id}.webp")
    end

    def self.furniture_icon(furniture_id)
      get("images/furniture/icon/#{furniture_id}.webp")
    end

    def self.equipment_icon(equipment_id)
      get("images/equipment/icon/#{equipment_id}.webp")
    end

    private

    def self.get(path)
      address = "#{HOST}/#{path}"
      Rails.logger.info("[SchaleDB::V1::Images] GET #{address}")
      uri = URI(address)
      Net::HTTP.get(uri)
    end
  end
end
