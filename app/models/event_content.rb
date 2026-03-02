class EventContent < ApplicationRecord
  include Translatable
  include EventMinigameable

  has_many :schedules, class_name: "EventContentSchedule", foreign_key: :event_content_uid, primary_key: :uid

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true

  BAQL_ID_PREFIX = "baql::events::"

  RUN_TYPE_MAP = {
    "Original"  => "first",
    "Rerun"     => "rerun",
    "Permanent" => "permanent"
  }.freeze

  REGION_MAP = {
    "Jp"     => "jp",
    "Global" => "gl",
    "Cn"     => "cn"
  }.freeze

  translatable :name

  KNOWN_REWARD_TYPES = %w[currency item equipment furniture].freeze

  def self.sync!
    # 이벤트 일정 동기화
    events_data = SchaleDB::V1::Data.events
    events = events_data["Events"] || []

    events.each do |event_data|
      event_id = event_data["Id"].to_s
      event_content = find_or_initialize_by(uid: event_id, baql_id: "#{BAQL_ID_PREFIX}#{event_id}")
      event_content.save!

      # Original, Rerun, Permanent 각각 처리
      RUN_TYPE_MAP.each do |run_type_key, run_type|
        next unless event_data[run_type_key]

        schedule_data = event_data[run_type_key]

        # 각 서버별로 일정 upsert
        REGION_MAP.each do |region_key, region|
          open_timestamp = schedule_data["EventOpen#{region_key}"]
          close_timestamp = schedule_data["EventClose#{region_key}"]
          next unless open_timestamp && close_timestamp

          start_at = timestamp_to_datetime(open_timestamp)
          end_at = timestamp_to_datetime(close_timestamp)
          next unless start_at

          schedule = event_content.schedules.find_or_initialize_by(region: region, run_type: run_type)
          schedule.update!(start_at: start_at, end_at: end_at)
        end
      end
    end

    # 이벤트 이름 번역 동기화
    Constants::LANGUAGE_MAP.each do |data_path, lang|
      localization_data = SchaleDB::V1::Data.localization(data_path)
      event_names = localization_data["EventName"] || {}
      event_names.each do |event_id, name|
        event_content = find_by(uid: event_id)
        event_content&.set_name(name, lang)
      end
    end

    nil
  end

  def translation_key_prefix
    baql_id
  end

  def stages(run_type: "first")
    raw = run_type == "rerun" ? raw_data_rerun : raw_data_first
    return [] unless raw

    (raw["stage"] || {}).flat_map do |stage_type, stage_list|
      stage_list.each_with_index.map do |s, index|
         {
          "uid"               => s["Id"].to_s,
          "stage_type"        => stage_type,
          "stage_index"       => index,
          "stage_number"      => s["StageNumber"].to_s,
          "enter_cost_type"   => s["StageEnterCostTypeStr"]&.downcase,
          "enter_cost_uid"    => s["StageEnterCostId"]&.to_s,
          "enter_cost_amount" => s["StageEnterCostAmount"],
          "rewards"           => normalize_rewards(s["EventContentStageReward"] || []),
        }
      end
    end
  end

  def bonuses(run_type: "first")
    raw = run_type == "rerun" ? raw_data_rerun : raw_data_first
    return [] unless raw

    item_type_to_uid = (raw["currency"] || []).each_with_object({}) do |c, h|
      h[c["EventContentItemType"]] = c["ItemUniqueId"].to_s
    end

    (raw["bonus"] || {}).flat_map do |student_uid, data|
      item_types  = data["EventContentItemType"] || []
      percentages = data["BonusPercentage"]      || []

      item_types.zip(percentages).filter_map do |item_type, raw_percentage|
        reward_uid = item_type_to_uid[item_type]
        next unless reward_uid

        {
          "student_uid" => student_uid,
          "reward_uid"  => reward_uid,
          "reward_type" => "item",
          "percentage"  => (BigDecimal(raw_percentage.to_s) / 10000),
        }
      end
    end
  end

  def shop_resources(run_type: "first")
    raw = run_type == "rerun" ? raw_data_rerun : raw_data_first
    return [] unless raw

    (raw["shop"] || {}).values.flat_map do |item_list|
      item_list.filter_map { |item| normalize_shop_item(item) }
    end
  end

  private

  def normalize_shop_item(item)
    goods = item["Goods"]&.first
    return nil unless goods

    {
      "uid"                     => item["Id"].to_s,
      "resource_type"           => goods["ParcelTypeStr"]&.first&.downcase,
      "resource_uid"            => goods["ParcelId"]&.first&.to_s,
      "resource_amount"         => goods["ParcelAmount"]&.first,
      "payment_resource_type"   => goods["ConsumeParcelTypeStr"]&.first&.downcase,
      "payment_resource_uid"    => goods["ConsumeParcelId"]&.first&.to_s,
      "payment_resource_amount" => goods["ConsumeParcelAmount"]&.first,
      "shop_amount"             => item["PurchaseCountLimit"]&.then { |n| n > 0 ? n : nil },
    }
  end

  def normalize_rewards(raw_rewards)
    raw_rewards
      .select { |r| KNOWN_REWARD_TYPES.include?(r["RewardParcelTypeStr"]&.downcase) }
      .map    { |r| normalize_reward(r) }
  end

  def normalize_reward(r)
    {
      "reward_uid"  => r["RewardId"].to_s,
      "reward_type" => r["RewardParcelTypeStr"].downcase,
      "amount"      => r["RewardAmount"],
      "probability" => (BigDecimal(r["RewardProb"].to_s) / 10000).to_s("F"),
      "tag"         => r["RewardTagStr"],
    }
  end

  def self.timestamp_to_datetime(timestamp)
    return nil if timestamp.nil? || timestamp >= 4102412400
    Time.zone.at(timestamp)
  end
end
