class Stage < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::stages::"

  ARMOR_TYPE_MAP = {
    "LightArmor"   => "light",
    "HeavyArmor"   => "heavy",
    "Unarmed"      => "special",
    "ElasticArmor" => "elastic",
  }.freeze

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true

  translatable :name

  def self.sync!
    SchaleDB::V1::Data.stages.each do |uid, raw_stage|
      uid = raw_stage["Id"]&.to_s || uid.to_s
      find_or_initialize_by(uid: uid)
        .update!(
          baql_id:      "#{BAQL_ID_PREFIX}#{uid}",
          category:     raw_stage["Category"].underscore,
          stage_type:   raw_stage["Type"]&.underscore,
          difficulty:   raw_stage["Difficulty"],
          area:         raw_stage["Area"],
          stage_number: raw_stage["Stage"]&.to_s,
          terrain:      raw_stage["Terrain"]&.downcase,
          level:        raw_stage["Level"],
          raw_data:     raw_stage,
        )
    end

    Constants::LANGUAGE_MAP.each do |data_path, lang|
      SchaleDB::V1::Data.stages(data_path).each do |uid, raw_stage|
        next unless raw_stage["Category"] == "Campaign"
        next unless raw_stage["Name"]

        stage = find_by(uid: uid.to_s)
        stage&.set_name(raw_stage["Name"], lang)
      end
    end

    nil
  end

  def translation_key_prefix = baql_id

  def defense_types
    Array(raw_data["ArmorTypes"]).filter_map { |armor_type| ARMOR_TYPE_MAP[armor_type] }.uniq
  end

  def entry_costs
    Array(raw_data["EntryCost"]).map do |cost|
      {
        "resource_type" => "currency",
        "resource_uid"  => cost[0]&.to_s,
        "amount"        => cost[1],
      }
    end
  end

  def star_condition
    normalize_condition(raw_data["StarCondition"])
  end

  def challenge_conditions
    Array(raw_data["ChallengeCondition"]).filter_map { |condition| normalize_condition(condition) }
  end

  def rewards(region: "jp")
    raw_rewards_for(region).map do |reward|
      {
        "reward_type" => reward["Type"]&.underscore,
        "reward_uid"  => reward["Id"]&.to_s,
        "amount"      => reward["Amount"],
        "amount_min"  => reward["AmountMin"],
        "amount_max"  => reward["AmountMax"],
        "probability" => reward["Chance"],
        "reward_tag"  => reward["RewardType"]&.underscore,
      }
    end
  end

  private

  def normalize_condition(condition)
    return nil unless condition

    {
      "type"  => condition[0].to_s.underscore,
      "value" => condition[1],
    }
  end

  def raw_rewards_for(region)
    case region
    when "gl"
      raw_data.dig("ServerData", "Global", "Rewards").presence || raw_data["Rewards"] || []
    when "cn"
      raw_data.dig("ServerData", "Cn", "Rewards").presence || raw_data["Rewards"] || []
    else
      raw_data["Rewards"] || []
    end
  end
end
