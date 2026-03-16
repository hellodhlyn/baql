class Currency < ApplicationRecord
  include ImageSyncable
  include Translatable

  BAQL_ID_PREFIX = "baql::currencies::"

  validates :uid, presence: true, uniqueness: true

  translatable :name, :description

  def self.sync!
    raw_currencies = SchaleDB::V1::Data.currencies
    raw_currencies.each do |raw_currency|
      uid = raw_currency["Id"].to_s
      currency = Currency.find_or_initialize_by(uid: uid, baql_id: "#{BAQL_ID_PREFIX}#{uid}")
      currency.update!(
        rarity:    case raw_currency["Rarity"]
          when "N"   then 1
          when "R"   then 2
          when "SR"  then 3
          when "SSR" then 4
          else raise "unknown rarity value: #{raw_currency["Rarity"].inspect} for currency #{uid}"
        end,
        raw_data: raw_currency,
      )

      if currency.saved_changes?
        Rails.logger.info("Currency #{raw_currency["Name"]}(#{currency.uid}) has been updated")
        sync_image!("assets/images/currencies/#{currency.uid}", SchaleDB::V1::Images.currency_icon(raw_currency["Icon"])) if raw_currency["Icon"].present?
      end
    end

    Constants::LANGUAGE_MAP.each do |data_path, lang|
      SchaleDB::V1::Data.currencies(data_path).each do |raw_currency|
        uid = raw_currency["Id"].to_s
        currency = Currency.find_by(uid: uid)
        next unless currency
        currency.set_name(raw_currency["Name"], lang)
        currency.set_description(raw_currency["Desc"], lang)
      end
    end

    nil
  end

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end
end
