require "rails_helper"

RSpec.describe SchaleDB::V1::Images do
  describe ".event_logo" do
    it "returns the image body for a webp response" do
      stub_request(:get, "https://schaledb.com/images/eventlogo/857_Jp.webp")
        .to_return(status: 200, headers: { "Content-Type" => "image/webp" }, body: "webp-body")

      expect(described_class.event_logo("857", "Jp")).to eq("webp-body")
    end

    it "returns nil when SchaleDB serves the app HTML instead of a webp image" do
      stub_request(:get, "https://schaledb.com/images/eventlogo/857_Kr.webp")
        .to_return(status: 200, headers: { "Content-Type" => "text/html; charset=utf-8" }, body: "<!DOCTYPE html>")

      expect(described_class.event_logo("857", "Kr")).to be_nil
    end
  end
end
