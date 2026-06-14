module ImageSyncable
  extend ActiveSupport::Concern

  class_methods do
    def image_storage_key(*segments)
      ["images", *segments].join("/")
    end

    def sync_image!(key, image_body)
      return if image_body.blank?

      bucket = ENV["ASSET_BUCKET_NAME"]
      return if image_exists?(bucket, key)

      Rails.logger.info("Syncing image '#{key}' to S3")
      s3_client.put_object(bucket: bucket, key: key, body: image_body)
    rescue => e
      Rails.logger.error("Failed to sync image '#{key}' to S3: #{e.message}")
    end

    def copy_image!(source_key, dest_key)
      bucket = ENV["ASSET_BUCKET_NAME"]
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

    def image_exists?(bucket, key)
      s3_client.head_object(bucket: bucket, key: key)
      Rails.logger.info("Skipping image '#{key}' because it already exists in S3")
      true
    rescue Aws::S3::Errors::NotFound
      false
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new
    end
  end
end
