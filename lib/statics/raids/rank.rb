module Statics::Raids
  class Rank
    def self.total_assault_parties(season_id)
      get_object("raids/total_assault/#{season_id}/parties.json.gz")
    end

    def self.elimination_parties(season_id, defense_type)
      get_object("raids/elimination/#{season_id}/parties_#{defense_type}.json.gz")
    end

    private

    def self.s3_client
      @s3_client ||= Aws::S3::Client.new
    end

    def self.get_object(key)
      Rails.logger.info("[Statics::Raids::Rank] Fetching '#{key}' from S3")
      raw_data = s3_client.get_object(bucket: ENV["STATIC_BUCKET_NAME"], key: key)
      decompress_json(raw_data.body.read)
    end

    def self.decompress_json(data)
      JSON.parse(ActiveSupport::Gzip.decompress(data)).map(&:deep_symbolize_keys)
    end
  end
end
