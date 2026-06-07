class GachaGroup < ApplicationRecord
  BAQL_ID_PREFIX = "baql::gacha_groups::"

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true

  def self.sync!
    SchaleDB::V1::Data.groups.each do |uid, raw_group|
      uid = raw_group["Id"]&.to_s || uid.to_s
      find_or_initialize_by(uid: uid)
        .update!(
          baql_id: "#{BAQL_ID_PREFIX}#{uid}",
          raw_data: raw_group,
        )
    end

    nil
  end

  def items(region: "jp")
    raw_items_for(region).map do |item|
      {
        "resource_type" => item["Type"]&.underscore,
        "resource_uid"  => item["Id"]&.to_s,
        "chance"        => item["Chance"],
        "amount_min"    => item["AmountMin"],
        "amount_max"    => item["AmountMax"],
      }
    end
  end

  private

  def raw_items_for(region)
    case region
    when "gl"
      raw_data["ItemsGlobal"].presence || raw_data["Items"] || []
    when "cn"
      raw_data["ItemsCn"].presence || raw_data["Items"] || []
    else
      raw_data["Items"] || []
    end
  end
end
