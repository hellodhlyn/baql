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

    private

    def s3_client
      @s3_client ||= Aws::S3::Client.new
    end
  end
end
