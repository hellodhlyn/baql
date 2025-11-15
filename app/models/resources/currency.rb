class Resources::Currency < Resource
  include ImageSyncable

  validates :uid, presence: true, uniqueness: true

  def self.sync!
    raw_currencies = SchaleDB::V1::Data.currencies
    raw_currencies.each do |raw_currency|
      uid = raw_currency["Id"].to_s
      currency = Resources::Currency.find_or_initialize_by(uid: uid)
      currency.update!(
        name: raw_currency["Name"],
        category: "currency",
        rarity: case raw_currency["Rarity"]
          when "N" then 1
          when "R" then 2
          when "SR" then 3
          when "SSR" then 4
          else raise "unknown rarity value: #{raw_currency["Rarity"].inspect} for currency #{uid}"
        end,
      )

      # if currency.saved_changes?
        Rails.logger.info("Currency #{currency.name}(#{currency.uid}) has been updated")
        sync_image!("assets/images/currencies/#{currency.uid}", SchaleDB::V1::Images.currency_icon(raw_currency["Icon"])) if raw_currency["Icon"].present?
      # end
    end

    nil
  end
end
