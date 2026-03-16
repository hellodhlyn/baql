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

    def self.currency_icon(currency_id)
      get("images/item/icon/#{currency_id}.webp")
    end

    def self.event_logo(event_uid, locale_suffix)
      get("images/eventlogo/#{event_uid}_#{locale_suffix}.webp")
    end

    private

    def self.get(path)
      address = "#{HOST}/#{path}"
      Rails.logger.info("[SchaleDB::V1::Images] GET #{address}")
      uri = URI(address)
      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      response.body
    end
  end
end
