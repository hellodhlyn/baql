module EventMinigameable
  extend ActiveSupport::Concern

  def minigame_configs(run_type: "first")
    raw = run_type == "rerun" ? raw_data_rerun : raw_data_first
    return [] unless raw

    types = raw.dig("season", "EventContentTypeStr") || []
    configs = []
    configs << normalize_card_shop_minigame(raw)      if types.include?("CardShop")
    configs << normalize_fortune_gacha_minigame(raw)  if types.include?("FortuneGachaShop")
    configs << normalize_box_gacha_minigame(raw)      if types.include?("BoxGacha")
    configs << normalize_concentration_minigame(raw)  if types.include?("Concentration")
    configs << normalize_treasure_minigame(raw)       if types.include?("Treasure")
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
        build_reward_group(build_slot_condition(slots, cycle_length), rewards, payment_range(payment))
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

    rewards = compute_card_slot_rewards(entries, gacha_groups: raw.dig("icons", "GachaGroup"))
    reward_groups = [build_reward_group({ "type" => "subsequent" }, rewards, payment_range(payment))]

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

      build_reward_group(condition, rewards, payment_range(payment))
    end

    { "minigame_type" => "box_gacha", "payment" => payment, "reward_groups" => reward_groups }
  end

  def normalize_concentration_minigame(raw)
    concentration = raw["concentration"].presence
    return nil unless concentration

    info    = concentration["info"]&.first
    cards   = concentration["card"]
    rewards = concentration["reward"]
    return nil unless info && cards && rewards

    cost = info["CostGoods"]
    payment = {
      "resource_type" => cost["ConsumeParcelTypeStr"]&.first&.downcase,
      "resource_uid"  => cost["ConsumeParcelId"]&.first&.to_s,
      "quantity"      => cost["ConsumeParcelAmount"]&.first.to_i * info["MaxCardOpenCount"].to_i,
    }

    rarity_counts = cards.each_with_object(Hash.new(0)) { |c, h| h[c["Rarity"]] += 1 }

    pair_totals = Hash.new(0.0)
    pair_meta   = {}
    rewards.select { |r| r["ConcentrationRewardTypeStr"] == "PairMatch" }.each do |entry|
      multiplier = rarity_counts[entry["Rarity"]] || 0
      entry["RewardParcelId"].each_with_index do |uid, i|
        type_str = entry["RewardParcelTypeStr"][i]&.downcase
        next unless EventContent::KNOWN_REWARD_TYPES.include?(type_str)

        key = "#{type_str}::#{uid}"
        pair_totals[key] += multiplier * entry["RewardParcelAmount"][i].to_f
        pair_meta[key] ||= { "resource_type" => type_str, "resource_uid" => uid.to_s }
      end
    end

    round_renewals = rewards.select { |r| r["ConcentrationRewardTypeStr"] == "RoundRenewal" }
    loop_round     = round_renewals.find { |r| r["IsLoop"] }&.dig("Round")

    reward_groups = round_renewals.sort_by { |r| r["Round"] }.map do |entry|
      round  = entry["Round"]
      totals = pair_totals.dup
      meta   = pair_meta.dup

      entry["RewardParcelId"].each_with_index do |uid, i|
        type_str = entry["RewardParcelTypeStr"][i]&.downcase
        next unless EventContent::KNOWN_REWARD_TYPES.include?(type_str)

        key = "#{type_str}::#{uid}"
        totals[key] += entry["RewardParcelAmount"][i].to_f
        meta[key] ||= { "resource_type" => type_str, "resource_uid" => uid.to_s }
      end

      combined_rewards = totals
        .map { |key, qty| meta[key].merge("quantity" => qty) }
        .sort_by { |r| [r["resource_type"], r["resource_uid"].to_i] }

      condition = if round == loop_round
        { "type" => "gte", "value" => round }
      else
        { "type" => "exact", "values" => [round] }
      end

      build_reward_group(condition, combined_rewards, payment_range(payment))
    end

    { "minigame_type" => "concentration", "payment" => payment, "reward_groups" => reward_groups }
  end

  def normalize_treasure_minigame(raw)
    treasure = raw["treasure"].presence
    return nil unless treasure

    rounds  = treasure["round"].presence
    rewards = treasure["reward"].presence
    return nil unless rounds && rewards

    first_round = rounds.first
    cost = first_round["CellCheckGoods"]
    first_payment_range = treasure_payment_range(first_round, rewards)
    payment = {
      "resource_type" => cost["ConsumeParcelTypeStr"]&.first&.downcase,
      "resource_uid"  => cost["ConsumeParcelId"]&.first&.to_s,
      "quantity"      => first_payment_range["quantity_expected"],
    }

    loop_round = treasure.dig("info", 0, "LoopRound")

    reward_groups = rounds.sort_by { |r| r["TreasureRound"] }.map do |round|
      totals = Hash.new(0.0)
      meta   = {}

      round["RewardId"].each_with_index do |reward_id, index|
        reward_amount = round["RewardAmount"][index].to_f
        reward_entry = rewards[reward_id.to_s]
        next unless reward_entry

        reward_entry["RewardParcelId"].each_with_index do |uid, parcel_index|
          type_str = reward_entry["RewardParcelTypeStr"][parcel_index]&.downcase
          next unless EventContent::KNOWN_REWARD_TYPES.include?(type_str)

          key = "#{type_str}::#{uid}"
          totals[key] += reward_amount * reward_entry["RewardParcelAmount"][parcel_index].to_f
          meta[key] ||= { "resource_type" => type_str, "resource_uid" => uid.to_s }
        end
      end

      normalized_rewards = totals
        .map { |key, qty| meta[key].merge("quantity" => qty) }
        .sort_by { |r| [r["resource_type"], r["resource_uid"].to_i] }

      condition = if round["TreasureRound"] == loop_round
        { "type" => "gte", "value" => round["TreasureRound"] }
      else
        { "type" => "exact", "values" => [round["TreasureRound"]] }
      end

      build_reward_group(condition, normalized_rewards, treasure_payment_range(round, rewards))
    end

    { "minigame_type" => "treasure_hunt", "payment" => payment, "reward_groups" => reward_groups }
  end

  def build_reward_group(condition, rewards, payment)
    { "condition" => condition, "payment" => payment, "rewards" => rewards }
  end

  def payment_range(payment)
    {
      "resource_type" => payment["resource_type"],
      "resource_uid"  => payment["resource_uid"],
      "quantity_min"      => payment["quantity"],
      "quantity_expected" => payment["quantity"],
      "quantity_max"      => payment["quantity"],
    }
  end

  def treasure_payment_range(round, rewards)
    cost = round["CellCheckGoods"]
    board_cells = (round["TreasureRoundSize"] || []).map(&:to_i).reduce(1, :*)
    cell_cost = cost["ConsumeParcelAmount"]&.first.to_i
    treasure_cells = round["RewardId"].each_with_index.sum do |reward_id, index|
      reward_entry = rewards[reward_id.to_s]
      next 0 unless reward_entry

      reward_entry["CellUnderImageWidth"].to_i *
        reward_entry["CellUnderImageHeight"].to_i *
        round["RewardAmount"][index].to_i
    end
    quantity_min = treasure_cells * cell_cost
    quantity_max = board_cells * cell_cost

    {
      "resource_type" => cost["ConsumeParcelTypeStr"]&.first&.downcase,
      "resource_uid"  => cost["ConsumeParcelId"]&.first&.to_s,
      "quantity_min"      => quantity_min,
      "quantity_expected" => ((quantity_min + quantity_max) / 2.0).ceil,
      "quantity_max"      => quantity_max,
    }
  end

  def compute_card_slot_rewards(cards, gacha_groups: nil)
    total_prob = cards.sum { |c| c["Prob"].to_f }
    expected   = Hash.new(0.0)
    meta       = {}

    cards.each do |card|
      weight = card["Prob"].to_f / total_prob
      card["RewardParcelId"].each_with_index do |uid, i|
        type_str = card["RewardParcelTypeStr"][i]&.downcase
        amount = card["RewardParcelAmount"][i].to_f

        if type_str == "gachagroup"
          accumulate_gacha_group_rewards(expected, meta, gacha_groups, uid, weight * amount)
          next
        end

        next unless EventContent::KNOWN_REWARD_TYPES.include?(type_str)

        key = "#{type_str}::#{uid}"
        expected[key] += weight * amount
        meta[key] ||= { "resource_type" => type_str, "resource_uid" => uid.to_s }
      end
    end

    expected
      .map { |key, qty| meta[key].merge("quantity" => qty) }
      .sort_by { |r| [r["resource_type"], r["resource_uid"].to_i] }
  end

  def accumulate_gacha_group_rewards(expected, meta, gacha_groups, group_uid, group_quantity)
    elements = gacha_groups&.dig(group_uid.to_s, "GachaElement")
    return if elements.blank?

    total_prob = elements.sum { |element| element["Prob"].to_f }
    return if total_prob <= 0

    elements.each do |element|
      type_str = element["ParcelTypeStr"]&.downcase
      next unless EventContent::KNOWN_REWARD_TYPES.include?(type_str)

      uid = element["ParcelId"]
      key = "#{type_str}::#{uid}"
      amount = gacha_group_element_expected_amount(element)
      expected[key] += group_quantity * (element["Prob"].to_f / total_prob) * amount
      meta[key] ||= { "resource_type" => type_str, "resource_uid" => uid.to_s }
    end
  end

  def gacha_group_element_expected_amount(element)
    min = element["ParcelAmountMin"].to_f
    max = element["ParcelAmountMax"].to_f
    (min + max) / 2.0
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
