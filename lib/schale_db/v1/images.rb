module SchaleDB::V1
  class Images
    HOST = "https://schaledb.com"

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
      return nil unless response.content_type == "image/webp"

      response.body
    end
  end
end
