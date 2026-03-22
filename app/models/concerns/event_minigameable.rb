module EventMinigameable
  extend ActiveSupport::Concern

  def minigame_configs(run_type: "first")
    raw = run_type == "rerun" ? raw_data_rerun : raw_data_first
    return [] unless raw

    types = raw.dig("season", "EventContentTypeStr") || []
    configs = []
    configs << normalize_card_shop_minigame(raw)    if types.include?("CardShop")
    configs << normalize_fortune_gacha_minigame(raw) if types.include?("FortuneGachaShop")
    configs << normalize_box_gacha_minigame(raw)    if types.include?("BoxGacha")
    configs.compact
  end

  private

  def normalize_card_shop_minigame(raw)
    entries = raw["card_shop"].presence
    return nil unless entries

    cost = entries.first["CostGoods"]
    payment = {
      "resource_type" => cost["ConsumeParcelTypeStr"]&.first&.downcase,
      "resource_uid"  => cost["ConsumeParcelId"]&.first&.to_s,
      "quantity"      => cost["ConsumeParcelAmount"]&.first,
    }

    by_slot = entries.group_by { |c| c["RefreshGroup"] }
    cycle_length = by_slot.keys.max

    per_slot_rewards = by_slot.sort.to_h do |slot, cards|
      [slot, compute_card_slot_rewards(cards)]
    end

    reward_groups = per_slot_rewards
      .group_by { |_, rewards| rewards_signature(rewards) }
      .map do |_, slot_pairs|
        slots   = slot_pairs.map(&:first).sort
        rewards = slot_pairs.first[1]
        { "condition" => build_slot_condition(slots, cycle_length), "rewards" => rewards }
      end
      .sort_by { |g| sort_key_for_condition(g["condition"]) }

    { "minigame_type" => "card_flip", "payment" => payment, "reward_groups" => reward_groups }
  end

  def normalize_fortune_gacha_minigame(raw)
    entries = raw.dig("fortune_gacha", "shop").presence
    return nil unless entries

    cost = entries.first["CostGoods"]
    payment = {
      "resource_type" => cost["ConsumeParcelTypeStr"]&.first&.downcase,
      "resource_uid"  => cost["ConsumeParcelId"]&.first&.to_s,
      "quantity"      => cost["ConsumeParcelAmount"]&.first,
    }

    rewards = compute_card_slot_rewards(entries)
    reward_groups = [{ "condition" => { "type" => "subsequent" }, "rewards" => rewards }]

    { "minigame_type" => "fortune_gacha", "payment" => payment, "reward_groups" => reward_groups }
  end

  def normalize_box_gacha_minigame(raw)
    shop    = raw.dig("box_gacha", "shop").presence
    manage  = raw.dig("box_gacha", "manage").presence
    return nil unless shop && manage

    first_manage = manage.first
    first_round  = first_manage["Round"]
    pool_size    = shop.select { |e| e["Round"] == first_round }.sum { |e| e["GroupElementAmount"] }
    cost_goods   = first_manage["Goods"]
    payment = {
      "resource_type" => cost_goods["ConsumeParcelTypeStr"]&.first&.downcase,
      "resource_uid"  => cost_goods["ConsumeParcelId"]&.first&.to_s,
      "quantity"      => cost_goods["ConsumeParcelAmount"]&.first.to_i * pool_size,
    }

    loop_round = manage.find { |m| m["IsLoop"] }&.dig("Round")

    reward_groups = shop.group_by { |e| e["Round"] }.sort.map do |round, entries|
      totals  = Hash.new(0.0)
      meta    = {}

      entries.each do |entry|
        count = entry["GroupElementAmount"].to_i
        goods = entry["Goods"][0]
        goods["ParcelId"].each_with_index do |uid, i|
          type_str = goods["ParcelTypeStr"][i]&.downcase
          next unless EventContent::KNOWN_REWARD_TYPES.include?(type_str)

          key = "#{type_str}::#{uid}"
          totals[key] += count * goods["ParcelAmount"][i].to_f
          meta[key] ||= { "resource_type" => type_str, "resource_uid" => uid.to_s }
        end
      end

      rewards = totals
        .map { |key, qty| meta[key].merge("quantity" => qty) }
        .sort_by { |r| [r["resource_type"], r["resource_uid"].to_i] }

      condition = if round == loop_round
        { "type" => "gte", "value" => round }
      else
        { "type" => "exact", "values" => [round] }
      end

      { "condition" => condition, "rewards" => rewards }
    end

    { "minigame_type" => "box_gacha", "payment" => payment, "reward_groups" => reward_groups }
  end

  def compute_card_slot_rewards(cards)
    total_prob = cards.sum { |c| c["Prob"].to_f }
    expected   = Hash.new(0.0)
    meta       = {}

    cards.each do |card|
      weight = card["Prob"].to_f / total_prob
      card["RewardParcelId"].each_with_index do |uid, i|
        type_str = card["RewardParcelTypeStr"][i]&.downcase
        next unless EventContent::KNOWN_REWARD_TYPES.include?(type_str)

        key = "#{type_str}::#{uid}"
        expected[key] += weight * card["RewardParcelAmount"][i].to_f
        meta[key] ||= { "resource_type" => type_str, "resource_uid" => uid.to_s }
      end
    end

    expected
      .map { |key, qty| meta[key].merge("quantity" => qty) }
      .sort_by { |r| [r["resource_type"], r["resource_uid"].to_i] }
  end

  # 동일한 보상 분포인지 비교하기 위한 정규화된 서명
  def rewards_signature(rewards)
    rewards
      .map { |r| [r["resource_type"], r["resource_uid"], r["quantity"].round(6)] }
      .sort
      .to_json
  end

  # slots: 동일 분포를 가진 슬롯 번호 배열 (정렬됨)
  # cycle_length: 한 사이클의 슬롯 수 (= max RefreshGroup)
  #
  # 지원하는 조건 타입:
  #   subsequent — 모든 슬롯에 적용 (슬롯 수 = 사이클 길이)
  #   modulo     — slot % divisor in remainders (반복 사이클 내 위치)
  def build_slot_condition(slots, cycle_length)
    if slots.length == cycle_length
      { "type" => "subsequent" }
    else
      remainders = slots.map { |s| s % cycle_length }.sort
      { "type" => "modulo", "divisor" => cycle_length, "remainders" => remainders }
    end
  end

  # 그룹 정렬 기준:
  #   subsequent → 0 (단독 그룹이므로 순서 무관)
  #   modulo     → 최소 나머지 기준 오름차순 (0은 사이클 끝이므로 divisor 취급)
  def sort_key_for_condition(condition)
    return 0 if condition["type"] == "subsequent"

    min_r = condition["remainders"]&.min || 0
    min_r == 0 ? condition["divisor"] : min_r
  end
end
