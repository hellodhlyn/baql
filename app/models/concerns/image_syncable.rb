module ImageSyncable
  extend ActiveSupport::Concern

  class_methods do
    def sync_image!(key, image_body)
      return if image_body.blank?
      Rails.logger.info("Syncing image '#{key}' to S3")
      s3_client.put_object(bucket: ENV["STATIC_BUCKET_NAME"], key: key, body: image_body)
    rescue => e
      Rails.logger.error("Failed to sync image '#{key}' to S3: #{e.message}")
    end

    def copy_image!(source_key, dest_key)
      bucket = ENV["STATIC_BUCKET_NAME"]
      Rails.logger.info("Copying image '#{source_key}' -> '#{dest_key}' in S3")
      s3_client.copy_object(
        bucket:      bucket,
        copy_source: "#{bucket}/#{source_key}",
        key:         dest_key,
      )
    rescue => e
      Rails.logger.error("Failed to copy image '#{source_key}' -> '#{dest_key}': #{e.message}")
    end

    private

    def s3_client
      @s3_client ||= Aws::S3::Client.new
    end
  end
end
