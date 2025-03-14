module Statics::Raids
  class Rank
    def self.parties(season_id)
      bucket_name = ENV["STATIC_BUCKET_NAME"]
      key = "raids/total_assault/#{season_id}/parties.json.gz"
      Rails.logger.info("[Statics::Raids::Rank] Fetching '#{key}' from S3")
      decompress_json(s3_client.get_object(bucket: bucket_name, key: key).body.read)
    end

    private

    def self.s3_client
      @s3_client ||= Aws::S3::Client.new
    end

    def self.decompress_json(data)
      JSON.parse(ActiveSupport::Gzip.decompress(data)).map(&:deep_symbolize_keys)
    end
  end
end
