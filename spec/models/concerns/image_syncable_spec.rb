require "rails_helper"

RSpec.describe ImageSyncable do
  let(:model_class) do
    Class.new do
      include ImageSyncable
    end
  end

  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:bucket) { "static-bucket" }
  let(:key) { "images/students/standing/13005.webp" }
  let(:body) { "image-body" }

  before do
    stub_const("ImageSyncableSpecModel", model_class)
    allow(model_class).to receive(:s3_client).and_return(s3_client)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ASSET_BUCKET_NAME").and_return(bucket)
  end

  describe ".sync_image!" do
    it "skips upload when the same key already exists in S3" do
      allow(s3_client).to receive(:head_object).with(bucket: bucket, key: key)
      allow(s3_client).to receive(:put_object)

      model_class.sync_image!(key, body)

      expect(s3_client).to have_received(:head_object).with(bucket: bucket, key: key)
      expect(s3_client).not_to have_received(:put_object)
    end

    it "uploads when the key does not exist in S3" do
      allow(s3_client).to receive(:head_object).with(bucket: bucket, key: key)
        .and_raise(Aws::S3::Errors::NotFound.new(nil, "not found"))
      allow(s3_client).to receive(:put_object)

      model_class.sync_image!(key, body)

      expect(s3_client).to have_received(:head_object).with(bucket: bucket, key: key)
      expect(s3_client).to have_received(:put_object).with(bucket: bucket, key: key, body: body)
    end

    it "does not check S3 when image body is blank" do
      allow(s3_client).to receive(:head_object)
      allow(s3_client).to receive(:put_object)

      model_class.sync_image!(key, nil)

      expect(s3_client).not_to have_received(:head_object)
      expect(s3_client).not_to have_received(:put_object)
    end
  end
end
