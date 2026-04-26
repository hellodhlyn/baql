require "rails_helper"

RSpec.describe EventMinigameable do
  def build_card(card_group_id:, ref_group:, prob:, rarity:, reward_ids:, reward_amounts:, reward_types:,
                 cost_id: 99, cost_amount: 200, cost_type: "Item")
    {
      "CardGroupId" => card_group_id,
      "CostGoodsId" => 1000,
      "Id" => rand(9999),
      "IsLegacy" => false,
      "Prob" => prob,
      "Rarity" => rarity,
      "RefreshGroup" => ref_group,
      "RewardParcelId" => reward_ids,
      "RewardParcelAmount" => reward_amounts,
      "RewardParcelTypeStr" => reward_types,
      "CostGoods" => {
        "ConsumeParcelId" => [cost_id],
        "ConsumeParcelAmount" => [cost_amount],
        "ConsumeParcelTypeStr" => [cost_type],
      },
    }
  end

  def build_ec(card_shop:)
    raw = {
      "season" => { "EventContentTypeStr" => ["Stage", "CardShop"] },
      "card_shop" => card_shop,
    }
    EventContent.new(uid: "850", baql_id: "baql::events::850", raw_data_first: raw)
  end

  def build_gacha_entry(prob:, reward_ids:, reward_amounts:, reward_types:,
                        cost_id: 80703, cost_amount: 1, cost_type: "Item")
    {
      "Id" => rand(9999),
      "Prob" => prob,
      "RewardParcelId" => reward_ids,
      "RewardParcelAmount" => reward_amounts,
      "RewardParcelTypeStr" => reward_types,
      "CostGoods" => {
        "ConsumeParcelId" => [cost_id],
        "ConsumeParcelAmount" => [cost_amount],
        "ConsumeParcelTypeStr" => [cost_type],
      },
    }
  end

  def build_fortune_gacha_ec(shop:, gacha_groups: nil)
    raw = {
      "season" => { "EventContentTypeStr" => ["FortuneGachaShop"] },
      "fortune_gacha" => { "shop" => shop },
    }
    raw["icons"] = { "GachaGroup" => gacha_groups } if gacha_groups
    EventContent.new(uid: "851", baql_id: "baql::events::851", raw_data_first: raw)
  end

  def qty(rewards, resource_type, uid)
    rewards
      .find { |r| r["resource_type"] == resource_type && r["resource_uid"] == uid.to_s }
      &.dig("quantity") || 0.0
  end

  # ──────────────────────────────────────────────────────────────
  # #minigame_configs — basic behavior
  # ──────────────────────────────────────────────────────────────
  describe "#minigame_configs" do
    context "when raw_data is nil" do
      subject { EventContent.new(uid: "1", baql_id: "baql::events::1") }

      it "returns an empty array" do
        expect(subject.minigame_configs).to eq([])
      end
    end

    context "when EventContentTypeStr does not include CardShop" do
      let(:raw) { { "season" => { "EventContentTypeStr" => ["Stage", "Shop"] }, "card_shop" => [] } }
      subject { EventContent.new(uid: "1", baql_id: "baql::events::1", raw_data_first: raw) }

      it "returns an empty array" do
        expect(subject.minigame_configs).to eq([])
      end
    end

    context "when run_type is rerun" do
      let(:rerun_raw) do
        {
          "season" => { "EventContentTypeStr" => ["CardShop"] },
          "card_shop" => [
            build_card(card_group_id: 1, ref_group: 1, prob: 100, rarity: 2,
                       reward_ids: [80], reward_amounts: [1], reward_types: ["Item"]),
          ],
        }
      end
      subject { EventContent.new(uid: "1", baql_id: "baql::events::1", raw_data_rerun: rerun_raw) }

      it "parses raw_data_rerun" do
        configs = subject.minigame_configs(run_type: "rerun")
        expect(configs.length).to eq(1)
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # CardShop normalization — payment / reward calculation
  # ──────────────────────────────────────────────────────────────
  describe "CardShop normalization" do
    #
    # Slots 1 & 2: 2 cards with the same distribution → merged → modulo(3), remainders=[1,2]
    #   - Card A (prob=200): item "80" ×4, currency "1" ×1000
    #   - Card B (prob=100): item "80" ×2, currency "1" ×500
    #   total_prob = 300
    #   → item "80":     (200×4 + 100×2) / 300 = 1000/300 ≈ 3.3333
    #   → currency "1":  (200×1000 + 100×500) / 300 = 250000/300 ≈ 833.3333
    #
    # Slot 3: 1 card with a different distribution → solo → modulo(3), remainders=[0]
    #   - Card C (prob=300): item "80" ×3
    #   → item "80": 3.0    (no currency "1")
    #
    let(:card_a1) do
      build_card(card_group_id: 100, ref_group: 1, prob: 200, rarity: 3,
                 reward_ids: [80, 1], reward_amounts: [4, 1000], reward_types: %w[Item Currency])
    end
    let(:card_b1) do
      build_card(card_group_id: 101, ref_group: 1, prob: 100, rarity: 2,
                 reward_ids: [80, 1], reward_amounts: [2, 500], reward_types: %w[Item Currency])
    end
    let(:card_a2) do  # slot 2: same distribution as slot 1
      build_card(card_group_id: 100, ref_group: 2, prob: 200, rarity: 3,
                 reward_ids: [80, 1], reward_amounts: [4, 1000], reward_types: %w[Item Currency])
    end
    let(:card_b2) do
      build_card(card_group_id: 101, ref_group: 2, prob: 100, rarity: 2,
                 reward_ids: [80, 1], reward_amounts: [2, 500], reward_types: %w[Item Currency])
    end
    let(:card_c3) do  # slot 3: different distribution
      build_card(card_group_id: 102, ref_group: 3, prob: 300, rarity: 1,
                 reward_ids: [80], reward_amounts: [3], reward_types: %w[Item])
    end

    subject(:ec) { build_ec(card_shop: [card_a1, card_b1, card_a2, card_b2, card_c3]) }
    let(:config) { ec.minigame_configs.first }

    describe "minigame_type" do
      it { expect(config["minigame_type"]).to eq("card_flip") }
    end

    describe "payment" do
      subject(:payment) { config["payment"] }

      it { expect(payment["resource_type"]).to eq("item") }
      it { expect(payment["resource_uid"]).to eq("99") }
      it { expect(payment["quantity"]).to eq(200) }
    end

    describe "reward_groups" do
      subject(:groups) { config["reward_groups"] }

      it "merges slots with identical distributions into one group" do
        expect(groups.length).to eq(2)
      end

      describe "merged group (slots 1 & 2)" do
        subject(:group) { groups.find { |g| g.dig("condition", "remainders") == [1, 2] } }

        it "uses modulo condition with divisor=cycle_length" do
          expect(group["condition"]["type"]).to eq("modulo")
          expect(group["condition"]["divisor"]).to eq(3)
          expect(group["condition"]["remainders"]).to eq([1, 2])
        end

        it "uses the deterministic payment quantity for min/expected/max" do
          expect(group["payment"]).to include(
            "resource_type" => "item",
            "resource_uid" => "99",
        "quantity_min" => 200,
        "quantity_expected" => 200,
        "quantity_max" => 200,
        "quantity_variable" => false,
      )
        end

        it "computes weighted expected quantity for item 80" do
          r = group["rewards"].find { |r| r["resource_type"] == "item" && r["resource_uid"] == "80" }
          expect(r["quantity"]).to be_within(0.0001).of(1000.0 / 300)
        end

        it "computes weighted expected quantity for currency 1" do
          r = group["rewards"].find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
          expect(r["quantity"]).to be_within(0.0001).of(250_000.0 / 300)
        end
      end

      describe "solo group (slot 3 → remainder 0)" do
        subject(:group) { groups.find { |g| g.dig("condition", "remainders") == [0] } }

        it "uses modulo condition with remainder 0" do
          expect(group["condition"]["type"]).to eq("modulo")
          expect(group["condition"]["divisor"]).to eq(3)
          expect(group["condition"]["remainders"]).to eq([0])
        end

        it "computes expected quantity for item 80" do
          r = group["rewards"].find { |r| r["resource_type"] == "item" && r["resource_uid"] == "80" }
          expect(r["quantity"]).to be_within(0.0001).of(3.0)
        end

        it "does not include currency 1" do
          r = group["rewards"].find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
          expect(r).to be_nil
        end
      end

      it "sorts groups: smaller min-remainder first (remainder 0 sorts last)" do
        conditions = groups.map { |g| g["condition"]["remainders"] }
        expect(conditions).to eq([[1, 2], [0]])
      end
    end

    describe "subsequent condition — all slots identical" do
      # All 3 slots have the same distribution → subsequent
      let(:card_slot1) do
        build_card(card_group_id: 100, ref_group: 1, prob: 100, rarity: 3,
                   reward_ids: [80], reward_amounts: [1], reward_types: %w[Item])
      end
      let(:card_slot2) do
        build_card(card_group_id: 100, ref_group: 2, prob: 100, rarity: 3,
                   reward_ids: [80], reward_amounts: [1], reward_types: %w[Item])
      end
      let(:card_slot3) do
        build_card(card_group_id: 100, ref_group: 3, prob: 100, rarity: 3,
                   reward_ids: [80], reward_amounts: [1], reward_types: %w[Item])
      end

      subject(:ec) { build_ec(card_shop: [card_slot1, card_slot2, card_slot3]) }
      let(:groups) { ec.minigame_configs.first["reward_groups"] }

      it "produces a single subsequent group" do
        expect(groups.length).to eq(1)
        expect(groups.first["condition"]["type"]).to eq("subsequent")
      end
    end

    describe "unknown reward types are filtered out" do
      let(:card_unknown) do
        build_card(card_group_id: 200, ref_group: 1, prob: 100, rarity: 0,
                   reward_ids: [99], reward_amounts: [1], reward_types: %w[Gacha])
      end

      subject(:ec) { build_ec(card_shop: [card_a1, card_unknown]) }

      it "excludes rewards with unknown ParcelTypeStr" do
        group = ec.minigame_configs.first["reward_groups"].first
        types = group["rewards"].map { |r| r["resource_type"] }
        expect(types).not_to include("gacha")
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # FortuneGachaShop normalization — Prob-weighted expected value
  # ──────────────────────────────────────────────────────────────
  describe "FortuneGachaShop normalization" do
    #
    # 3 entries, total_prob = 1000
    #   - Entry A (prob=100): GachaGroup 300001×1, currency "1" ×1000
    #   - Entry B (prob=200): GachaGroup 300002×2, currency "1" ×500
    #   - Entry C (prob=700): item "80" ×5                              → item: 0.7×5=3.5
    #   GachaGroup 300001 has two equally weighted item leaves:
    #     item "100" ×1, item "110" ×1 → each 0.1×1×0.5=0.05
    #   GachaGroup 300002 has one item leaf with a quantity range:
    #     item "120" ×2..4 → 0.2×2×3=1.2
    #
    let(:entry_a) do
      build_gacha_entry(prob: 100,
                        reward_ids: [300001, 1], reward_amounts: [1, 1000],
                        reward_types: %w[GachaGroup Currency])
    end
    let(:entry_b) do
      build_gacha_entry(prob: 200,
                        reward_ids: [300002, 1], reward_amounts: [2, 500],
                        reward_types: %w[GachaGroup Currency])
    end
    let(:entry_c) do
      build_gacha_entry(prob: 700,
                        reward_ids: [80], reward_amounts: [5],
                        reward_types: %w[Item])
    end
    let(:gacha_groups) do
      {
        "300001" => {
          "GachaElement" => [
            {
              "GachaGroupId" => 300001,
              "ParcelAmountMax" => 1,
              "ParcelAmountMin" => 1,
              "ParcelId" => 100,
              "ParcelTypeStr" => "Item",
              "Prob" => 1,
            },
            {
              "GachaGroupId" => 300001,
              "ParcelAmountMax" => 1,
              "ParcelAmountMin" => 1,
              "ParcelId" => 110,
              "ParcelTypeStr" => "Item",
              "Prob" => 1,
            },
          ],
        },
        "300002" => {
          "GachaElement" => [
            {
              "GachaGroupId" => 300002,
              "ParcelAmountMax" => 4,
              "ParcelAmountMin" => 2,
              "ParcelId" => 120,
              "ParcelTypeStr" => "Item",
              "Prob" => 1,
            },
          ],
        },
        "300003" => {
          "GachaElementRecursive" => [
            {
              "GachaGroupId" => 300003,
              "ParcelAmountMax" => 1,
              "ParcelAmountMin" => 1,
              "ParcelId" => 300001,
              "ParcelTypeStr" => "GachaGroup",
              "Prob" => 1,
            },
          ],
        },
      }
    end

    subject(:ec) { build_fortune_gacha_ec(shop: [entry_a, entry_b, entry_c], gacha_groups: gacha_groups) }
    let(:config) { ec.minigame_configs.first }

    it "returns minigame_type fortune_gacha" do
      expect(config["minigame_type"]).to eq("fortune_gacha")
    end

    describe "payment" do
      subject(:payment) { config["payment"] }

      it { expect(payment["resource_type"]).to eq("item") }
      it { expect(payment["resource_uid"]).to eq("80703") }
      it { expect(payment["quantity"]).to eq(1) }
    end

    describe "reward_groups" do
      subject(:groups) { config["reward_groups"] }

      it "produces exactly one subsequent group" do
        expect(groups.length).to eq(1)
        expect(groups.first["condition"]["type"]).to eq("subsequent")
      end

      describe "expected reward quantities" do
        subject(:rewards) { groups.first["rewards"] }

        it "computes weighted currency(1) = 200" do
          r = rewards.find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
          expect(r["quantity"]).to be_within(0.0001).of(200.0)
        end

        it "computes weighted item(80) = 3.5" do
          r = rewards.find { |r| r["resource_type"] == "item" && r["resource_uid"] == "80" }
          expect(r["quantity"]).to be_within(0.0001).of(3.5)
        end

        it "does not include GachaGroup rewards directly" do
          types = rewards.map { |r| r["resource_type"] }
          expect(types).not_to include("gachagroup")
        end

        it "expands equally weighted GachaGroup leaves" do
          expect(qty(rewards, "item", 100)).to be_within(0.0001).of(0.05)
          expect(qty(rewards, "item", 110)).to be_within(0.0001).of(0.05)
        end

        it "uses the average of ranged GachaGroup leaf amounts" do
          expect(qty(rewards, "item", 120)).to be_within(0.0001).of(1.2)
        end
      end
    end

    context "when fortune_gacha key is absent" do
      subject(:ec) do
        raw = { "season" => { "EventContentTypeStr" => ["FortuneGachaShop"] } }
        EventContent.new(uid: "851", baql_id: "baql::events::851", raw_data_first: raw)
      end

      it "returns an empty array" do
        expect(ec.minigame_configs).to eq([])
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # event 853 fixture data — FortuneGachaShop with GachaGroup leaves
  # ──────────────────────────────────────────────────────────────
  describe "event 853 real data (FortuneGachaShop GachaGroup expansion)" do
    let(:raw)    { JSON.parse(ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/event.853.json.gz"))) }
    let(:ec)     { EventContent.new(uid: "853", baql_id: "baql::events::853", raw_data_first: raw) }
    let(:config) { ec.minigame_configs.first }
    let(:rewards) { config["reward_groups"].first["rewards"] }

    it "returns minigame_type fortune_gacha" do
      expect(config["minigame_type"]).to eq("fortune_gacha")
    end

    it "does not include GachaGroup rewards directly" do
      types = rewards.map { |r| r["resource_type"] }
      expect(types).not_to include("gachagroup")
    end

    it "keeps direct rewards" do
      expect(qty(rewards, "currency", 1)).to be_within(1.0).of(411_000.0)
      expect(qty(rewards, "item", 23)).to be_within(0.0001).of(1.505)
    end

    it "expands lower artifact GachaGroup rewards" do
      [160, 190, 220, 280].each do |uid|
        expect(qty(rewards, "item", uid)).to be_within(0.0001).of(0.65)
      end
    end

    it "expands middle artifact GachaGroup rewards" do
      [161, 191, 221, 281].each do |uid|
        expect(qty(rewards, "item", uid)).to be_within(0.0001).of(0.3675)
      end
    end

    it "expands high artifact GachaGroup rewards" do
      [162, 192, 222, 282].each do |uid|
        expect(qty(rewards, "item", uid)).to be_within(0.0001).of(0.1625)
      end
    end

    it "expands highest artifact GachaGroup rewards" do
      [163, 193, 223, 283].each do |uid|
        expect(qty(rewards, "item", uid)).to be_within(0.0001).of(0.040625)
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # event 851 fixture data — FortuneGachaShop
  # ──────────────────────────────────────────────────────────────
  describe "event 851 real data (FortuneGachaShop)" do
    let(:raw)    { JSON.parse(ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/event.851.json.gz"))) }
    let(:ec)     { EventContent.new(uid: "851", baql_id: "baql::events::851", raw_data_first: raw) }
    let(:config) { ec.minigame_configs.first }
    let(:groups) { config["reward_groups"] }

    it "returns minigame_type fortune_gacha" do
      expect(config["minigame_type"]).to eq("fortune_gacha")
    end

    describe "payment" do
      it "uses item 80703 × 1" do
        expect(config["payment"]["resource_type"]).to eq("item")
        expect(config["payment"]["resource_uid"]).to eq("80703")
        expect(config["payment"]["quantity"]).to eq(1)
      end
    end

    describe "reward_groups" do
      it "produces a single subsequent group" do
        expect(groups.length).to eq(1)
        expect(groups.first["condition"]["type"]).to eq("subsequent")
      end
    end

    # total_prob = 10000
    # currency(1):
    #   Grade 0 (prob 1200): 300000 → 36000
    #   Grade 1 (prob 1400×2): 200000 → 28000×2 = 56000
    #   Grade 2 (prob 875×4): 200000 → 17500×4 = 70000
    #   Grade 3 (prob 500×4): 150000 → 7500×4  = 30000
    #   Grade 4 (prob 125×4): 100000 → 1250×4  =  5000
    #   total = 197000
    #
    # item(23): entries 210, 217-220 (×1 each), 221-224 (×1 each)
    #   entry 210:    1200/10000 × 1 = 0.12
    #   entries 217-220: 500/10000 × 1 × 4 = 0.20
    #   entries 221-224: 125/10000 × 1 × 4 = 0.05
    #   total = 0.37
    describe "per-pull expected reward quantities" do
      subject(:rewards) { groups.first["rewards"] }

      def qty(resource_type, uid)
        rewards
          .find { |r| r["resource_type"] == resource_type && r["resource_uid"] == uid.to_s }
          &.dig("quantity") || 0.0
      end

      it "currency(1) ≈ 197000" do
        expect(qty("currency", 1)).to be_within(1.0).of(197_000.0)
      end

      it "item(23) ≈ 0.37" do
        expect(qty("item", 23)).to be_within(0.001).of(0.37)
      end

      it "does not include GachaGroup rewards" do
        types = rewards.map { |r| r["resource_type"] }
        expect(types).not_to include("gachagroup")
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # BoxGacha normalization — finite pool, total quantities per round
  # ──────────────────────────────────────────────────────────────
  describe "BoxGacha normalization" do
    def build_box_entry(round:, goods_list:)
      goods_list.map do |g|
        {
          "Round"              => round,
          "GroupElementAmount" => g[:count],
          "IsPrize"            => g.fetch(:prize, false),
          "IsLegacy"           => false,
          "Goods"              => [{
            "ParcelTypeStr"        => [g[:type]],
            "ParcelId"             => [g[:uid]],
            "ParcelAmount"         => [g[:amount]],
            "ConsumeParcelTypeStr" => ["Item"],
            "ConsumeParcelId"      => [99],
            "ConsumeParcelAmount"  => [6],
          }],
        }
      end
    end

    def build_manage(round:, is_loop:, cost_id: 99, cost_amount: 6)
      {
        "Round"  => round,
        "IsLoop" => is_loop,
        "Goods"  => {
          "ConsumeParcelTypeStr" => ["Item"],
          "ConsumeParcelId"      => [cost_id],
          "ConsumeParcelAmount"  => [cost_amount],
        },
      }
    end

    def build_box_gacha_ec(shop:, manage:)
      raw = {
        "season"    => { "EventContentTypeStr" => ["Stage", "BoxGacha"] },
        "box_gacha" => { "shop" => shop.flatten, "manage" => manage },
      }
      EventContent.new(uid: "10839", baql_id: "baql::events::10839", raw_data_first: raw)
    end

    let(:round1_shop) do
      build_box_entry(round: 1, goods_list: [
        { count: 5, type: "Currency", uid: 1, amount: 100_000 },
        { count: 2, type: "Item",     uid: 80, amount: 1 },
      ])
    end
    let(:round2_shop) do
      build_box_entry(round: 2, goods_list: [
        { count: 3, type: "Currency", uid: 1, amount: 50_000 },
        { count: 1, type: "Item",     uid: 80, amount: 5, prize: true },
      ])
    end
    let(:manage_entries) do
      [
        build_manage(round: 1, is_loop: false),
        build_manage(round: 2, is_loop: true),
      ]
    end

    subject(:ec)     { build_box_gacha_ec(shop: [round1_shop, round2_shop], manage: manage_entries) }
    subject(:config) { ec.minigame_configs.first }

    it "returns minigame_type box_gacha" do
      expect(config["minigame_type"]).to eq("box_gacha")
    end

    describe "payment" do
      subject(:payment) { config["payment"] }

      it { expect(payment["resource_type"]).to eq("item") }
      it { expect(payment["resource_uid"]).to eq("99") }
      it { expect(payment["quantity"]).to eq(6 * 7) }
    end

    describe "reward_groups" do
      subject(:groups) { config["reward_groups"] }

      it "produces one group per round" do
        expect(groups.length).to eq(2)
      end

      describe "non-loop round (round 1)" do
        subject(:group) { groups.find { |g| g.dig("condition", "type") == "exact" } }

        it "uses exact condition with values=[1]" do
          expect(group["condition"]["values"]).to eq([1])
        end

        it "aggregates currency(1) as 5×100000=500000" do
          r = group["rewards"].find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
          expect(r["quantity"]).to eq(500_000.0)
        end

        it "aggregates item(80) as 2×1=2" do
          r = group["rewards"].find { |r| r["resource_type"] == "item" && r["resource_uid"] == "80" }
          expect(r["quantity"]).to eq(2.0)
        end
      end

      describe "loop round (round 2)" do
        subject(:group) { groups.find { |g| g.dig("condition", "type") == "gte" } }

        it "uses gte condition with value=2" do
          expect(group["condition"]["value"]).to eq(2)
        end

        it "aggregates currency(1) as 3×50000=150000" do
          r = group["rewards"].find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
          expect(r["quantity"]).to eq(150_000.0)
        end

        it "aggregates item(80) as 1×5=5" do
          r = group["rewards"].find { |r| r["resource_type"] == "item" && r["resource_uid"] == "80" }
          expect(r["quantity"]).to eq(5.0)
        end
      end

      describe "aggregation of same reward across multiple entries" do
        let(:shop) do
          build_box_entry(round: 1, goods_list: [
            { count: 3, type: "Currency", uid: 1, amount: 100_000 },
            { count: 2, type: "Currency", uid: 1, amount: 50_000 },
          ])
        end
        let(:ec) { build_box_gacha_ec(shop: [shop], manage: [build_manage(round: 1, is_loop: true)]) }
        let(:group) { ec.minigame_configs.first["reward_groups"].first }

        it "sums identical resource across pool entries" do
          r = group["rewards"].find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
          expect(r["quantity"]).to eq(3 * 100_000.0 + 2 * 50_000.0)
        end
      end

      describe "unknown reward types are filtered" do
        let(:shop) do
          build_box_entry(round: 1, goods_list: [
            { count: 1, type: "GachaGroup", uid: 999, amount: 1 },
            { count: 2, type: "Item",       uid: 80,  amount: 1 },
          ])
        end
        let(:ec) { build_box_gacha_ec(shop: [shop], manage: [build_manage(round: 1, is_loop: true)]) }
        let(:group) { ec.minigame_configs.first["reward_groups"].first }

        it "excludes unknown reward types" do
          types = group["rewards"].map { |r| r["resource_type"] }
          expect(types).not_to include("gachagroup")
        end
      end
    end

    context "when box_gacha key is absent" do
      subject(:ec) do
        raw = { "season" => { "EventContentTypeStr" => ["BoxGacha"] } }
        EventContent.new(uid: "1", baql_id: "baql::events::1", raw_data_first: raw)
      end

      it "returns an empty array" do
        expect(ec.minigame_configs).to eq([])
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # event 10839 fixture data — BoxGacha
  # ──────────────────────────────────────────────────────────────
  describe "event 10839 real data (BoxGacha)" do
    let(:raw)    { JSON.parse(ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/event.10839.json.gz"))) }
    let(:ec)     { EventContent.new(uid: "10839", baql_id: "baql::events::10839", raw_data_first: raw) }
    let(:config) { ec.minigame_configs.first }
    let(:groups) { config["reward_groups"] }

    it "returns minigame_type box_gacha" do
      expect(config["minigame_type"]).to eq("box_gacha")
    end

    describe "payment" do
      it "uses item 85340, total cost = 6 × 300 = 1800" do
        expect(config["payment"]["resource_type"]).to eq("item")
        expect(config["payment"]["resource_uid"]).to eq("85340")
        expect(config["payment"]["quantity"]).to eq(1800)
      end
    end

    describe "reward_groups" do
      it "produces 9 groups (rounds 1-8 + loop round 9)" do
        expect(groups.length).to eq(9)
      end

      it "rounds 1-8 use exact conditions" do
        exact_groups = groups.select { |g| g.dig("condition", "type") == "exact" }
        expect(exact_groups.length).to eq(8)
        expect(exact_groups.map { |g| g.dig("condition", "values") }.sort).to eq((1..8).map { |r| [r] })
      end

      it "round 9 uses gte condition" do
        loop_group = groups.find { |g| g.dig("condition", "type") == "gte" }
        expect(loop_group["condition"]["value"]).to eq(9)
      end

      describe "round 1 reward totals" do
        subject(:rewards) { groups.find { |g| g.dig("condition", "values") == [1] }["rewards"] }

        def qty(type, uid)
          rewards.find { |r| r["resource_type"] == type && r["resource_uid"] == uid.to_s }&.dig("quantity") || 0.0
        end

        it "currency(1) = 3×300000 + 8×150000 + 15×75000 + 20×30000 = 3825000" do
          expect(qty("currency", 1)).to eq(3_825_000.0)
        end

        it "currency(3) = 1×150 = 150" do
          expect(qty("currency", 3)).to eq(150.0)
        end

        it "item(85343) = 2×10 = 20" do
          expect(qty("item", 85_343)).to eq(20.0)
        end
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # event 850 fixture data — CardShop
  # ──────────────────────────────────────────────────────────────
  describe "event 850 real data" do
    let(:raw)    { JSON.parse(ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/event.850.json.gz"))) }
    let(:ec)     { EventContent.new(uid: "850", baql_id: "baql::events::850", raw_data_first: raw) }
    let(:config) { ec.minigame_configs.first }
    let(:groups) { config["reward_groups"] }

    describe "payment" do
      it "uses item 80680 as payment resource" do
        expect(config["payment"]["resource_uid"]).to eq("80680")
        expect(config["payment"]["resource_type"]).to eq("item")
      end

      it "costs 200 per card" do
        expect(config["payment"]["quantity"]).to eq(200)
      end
    end

    # event 850: slot 4 (RefreshGroup 4, 7 cards) has a different distribution from slots 1-3 (11 cards)
    # slot 4 contains only rarity 2/3 cards, so its expected rewards are higher
    describe "reward groups structure" do
      it "produces 2 groups (slots 1-3 share one distribution, slot 4 another)" do
        expect(groups.length).to eq(2)
      end

      it "uses modulo(4) conditions for both groups" do
        expect(groups.map { |g| g.dig("condition", "type") }).to all(eq("modulo"))
        expect(groups.map { |g| g.dig("condition", "divisor") }).to all(eq(4))
      end

      it "sorts groups: remainders [1,2,3] first, [0] (slot 4) last" do
        expect(groups.map { |g| g.dig("condition", "remainders") }).to eq([[1, 2, 3], [0]])
      end
    end

    describe "per-slot expected reward quantities (slot 1-3 group)" do
      subject(:rewards) { groups.find { |g| g.dig("condition", "remainders") == [1, 2, 3] }["rewards"] }

      def qty(resource_type, uid)
        rewards
          .find { |r| r["resource_type"] == resource_type && r["resource_uid"] == uid.to_s }
          &.dig("quantity") || 0.0
      end

      it "currency(1)  ≈ 149350.0" do expect(qty("currency",  1)).to be_within(1.0).of(149_350.0) end
      it "item(80683)  ≈ 1.755"    do expect(qty("item",  80683)).to be_within(0.01).of(1.755)  end
      it "item(13)     ≈ 0.12"     do expect(qty("item",     13)).to be_within(0.01).of(0.12)   end
      it "equipment(4) ≈ 0.12"     do expect(qty("equipment", 4)).to be_within(0.01).of(0.12)  end
    end

    describe "per-slot expected reward quantities (slot 4 group)" do
      subject(:rewards) { groups.find { |g| g.dig("condition", "remainders") == [0] }["rewards"] }

      def qty(resource_type, uid)
        rewards
          .find { |r| r["resource_type"] == resource_type && r["resource_uid"] == uid.to_s }
          &.dig("quantity") || 0.0
      end

      # slot 4 has only high-rarity cards, so currency expected value is higher than slots 1-3
      it "currency(1) is higher than slot 1-3 group" do
        slot_1_3_currency = groups.find { |g| g.dig("condition", "remainders") == [1, 2, 3] }["rewards"]
                                  .find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
                                  &.dig("quantity") || 0.0
        expect(qty("currency", 1)).to be > slot_1_3_currency
      end

      it "currency(1) ≈ 255000.0 (remaining from total 703050 - 3 × 149350)" do
        expect(qty("currency", 1)).to be_within(1.0).of(255_000.0)
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Concentration normalization — deterministic per-round totals
  # ──────────────────────────────────────────────────────────────
  describe "Concentration normalization" do
    def build_concentration_info(cost_id:, cost_amount:, cost_type: "Item", max_card_open: 12, max_card_pair: 6)
      {
        "MaxCardOpenCount" => max_card_open,
        "MaxCardPairCount" => max_card_pair,
        "CostGoods" => {
          "ConsumeParcelTypeStr" => [cost_type],
          "ConsumeParcelId"      => [cost_id],
          "ConsumeParcelAmount"  => [cost_amount],
        },
      }
    end

    def build_concentration_card(card_id:, rarity:)
      { "CardId" => card_id, "Rarity" => rarity }
    end

    def build_concentration_reward(type_str:, round:, rarity: 0, is_loop: false,
                                   reward_ids:, reward_amounts:, reward_types:)
      {
        "ConcentrationRewardTypeStr" => type_str,
        "Round"              => round,
        "Rarity"             => rarity,
        "IsLoop"             => is_loop,
        "RewardParcelId"     => reward_ids,
        "RewardParcelAmount" => reward_amounts,
        "RewardParcelTypeStr" => reward_types,
      }
    end

    def build_concentration_ec(info:, card:, reward:)
      raw = {
        "season"        => { "EventContentTypeStr" => ["Concentration"] },
        "concentration" => { "info" => [info], "card" => card, "reward" => reward },
      }
      EventContent.new(uid: "852", baql_id: "baql::events::852", raw_data_first: raw)
    end

    # 2 cards (rarity 0 × 1, rarity 1 × 1)
    # PairMatch rarity 0: item 80 × 10
    # PairMatch rarity 1: item 80 × 5, currency 1 × 200
    # RoundRenewal round 1 (fixed): currency 1 × 1000
    # RoundRenewal round 2 (loop): item 99 × 3
    let(:info)  { build_concentration_info(cost_id: 777, cost_amount: 100, max_card_open: 4, max_card_pair: 1) }
    let(:cards) do
      [
        build_concentration_card(card_id: 1, rarity: 0),
        build_concentration_card(card_id: 2, rarity: 1),
      ]
    end
    let(:rewards) do
      [
        build_concentration_reward(type_str: "PairMatch", round: 0, rarity: 0,
                                   reward_ids: [80], reward_amounts: [10], reward_types: %w[Item]),
        build_concentration_reward(type_str: "PairMatch", round: 0, rarity: 1,
                                   reward_ids: [80, 1], reward_amounts: [5, 200], reward_types: %w[Item Currency]),
        build_concentration_reward(type_str: "RoundRenewal", round: 1, is_loop: false,
                                   reward_ids: [1], reward_amounts: [1000], reward_types: %w[Currency]),
        build_concentration_reward(type_str: "RoundRenewal", round: 2, is_loop: true,
                                   reward_ids: [99], reward_amounts: [3], reward_types: %w[Item]),
      ]
    end

    subject(:ec)     { build_concentration_ec(info: info, card: cards, reward: rewards) }
    subject(:config) { ec.minigame_configs.first }

    it "returns minigame_type concentration" do
      expect(config["minigame_type"]).to eq("concentration")
    end

    describe "payment" do
      subject(:payment) { config["payment"] }

      it { expect(payment["resource_type"]).to eq("item") }
      it { expect(payment["resource_uid"]).to eq("777") }
      it { expect(payment["quantity"]).to eq(400) }
    end

    describe "payment ranges" do
      subject(:payment) { config["reward_groups"].first["payment"] }

      it "uses pair count as min, max open count as max, and a concentration heuristic as expected" do
        expect(payment).to include(
          "resource_type" => "item",
          "resource_uid" => "777",
          "quantity_min" => 100,
          "quantity_expected" => 300,
          "quantity_max" => 400,
          "quantity_variable" => true,
        )
      end
    end

    describe "reward_groups" do
      subject(:groups) { config["reward_groups"] }

      it "produces one group per round" do
        expect(groups.length).to eq(2)
      end

      it "non-loop round uses exact condition" do
        g = groups.find { |g| g.dig("condition", "type") == "exact" }
        expect(g["condition"]["values"]).to eq([1])
      end

      it "loop round uses gte condition" do
        g = groups.find { |g| g.dig("condition", "type") == "gte" }
        expect(g["condition"]["value"]).to eq(2)
      end

      describe "round 1 combined rewards" do
        # PairMatch: rarity_0(×1)→item80×10, rarity_1(×1)→item80×5 + currency1×200
        #   → item80 = 15, currency1 = 200
        # RoundRenewal round1: currency1 × 1000
        #   → currency1 total = 1200, item80 = 15
        subject(:r1) { groups.find { |g| g.dig("condition", "values") == [1] }["rewards"] }

        it "sums PairMatch item(80) across rarities: 10×1 + 5×1 = 15" do
          r = r1.find { |r| r["resource_type"] == "item" && r["resource_uid"] == "80" }
          expect(r["quantity"]).to eq(15.0)
        end

        it "sums PairMatch currency(1) + RoundRenewal currency(1): 200 + 1000 = 1200" do
          r = r1.find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
          expect(r["quantity"]).to eq(1200.0)
        end

        it "does not include item(99) from round 2" do
          expect(r1.map { |r| r["resource_uid"] }).not_to include("99")
        end
      end

      describe "round 2 combined rewards (loop)" do
        # PairMatch same as always: item80=15, currency1=200
        # RoundRenewal round2: item99×3
        subject(:r2) { groups.find { |g| g.dig("condition", "type") == "gte" }["rewards"] }

        it "includes PairMatch rewards" do
          r = r2.find { |r| r["resource_type"] == "item" && r["resource_uid"] == "80" }
          expect(r["quantity"]).to eq(15.0)
        end

        it "includes RoundRenewal item(99) × 3" do
          r = r2.find { |r| r["resource_type"] == "item" && r["resource_uid"] == "99" }
          expect(r["quantity"]).to eq(3.0)
        end

        it "does not include currency(1) from round 1 RoundRenewal" do
          r = r2.find { |r| r["resource_type"] == "currency" && r["resource_uid"] == "1" }
          expect(r["quantity"]).to eq(200.0)  # PairMatch only, not 1200
        end
      end
    end

    describe "unknown reward types are filtered out" do
      let(:rewards) do
        [
          build_concentration_reward(type_str: "PairMatch", round: 0, rarity: 0,
                                     reward_ids: [999, 80], reward_amounts: [1, 5],
                                     reward_types: %w[GachaGroup Item]),
          build_concentration_reward(type_str: "RoundRenewal", round: 1, is_loop: true,
                                     reward_ids: [1], reward_amounts: [100], reward_types: %w[Currency]),
        ]
      end

      it "excludes GachaGroup from rewards" do
        group = ec.minigame_configs.first["reward_groups"].first
        types = group["rewards"].map { |r| r["resource_type"] }
        expect(types).not_to include("gachagroup")
      end
    end

    context "when concentration key is absent" do
      subject(:ec) do
        raw = { "season" => { "EventContentTypeStr" => ["Concentration"] } }
        EventContent.new(uid: "852", baql_id: "baql::events::852", raw_data_first: raw)
      end

      it "returns an empty array" do
        expect(ec.minigame_configs).to eq([])
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # event 852 fixture data — Concentration
  # ──────────────────────────────────────────────────────────────
  describe "event 852 real data (Concentration)" do
    let(:raw)    { JSON.parse(ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/event.852.json.gz"))) }
    let(:ec)     { EventContent.new(uid: "852", baql_id: "baql::events::852", raw_data_first: raw) }
    let(:config) { ec.minigame_configs.first }
    let(:groups) { config["reward_groups"] }

    it "returns minigame_type concentration" do
      expect(config["minigame_type"]).to eq("concentration")
    end

    describe "payment" do
      it "keeps the legacy quantity at max attempts 12 × 170 = 2040" do
        expect(config["payment"]["resource_type"]).to eq("item")
        expect(config["payment"]["resource_uid"]).to eq("80710")
        expect(config["payment"]["quantity"]).to eq(2040)
      end

      it "uses pair count, heuristic expected attempts, and max open count for the range" do
        payment = groups.first["payment"]
        expect(payment).to include(
          "quantity_min" => 1020,
          "quantity_expected" => 1870,
          "quantity_max" => 2040,
          "quantity_variable" => true,
        )
      end
    end

    describe "reward_groups" do
      it "produces 10 groups (rounds 1-9 exact, round 10 gte)" do
        expect(groups.length).to eq(10)
      end

      it "rounds 1-9 use exact conditions" do
        exact_groups = groups.select { |g| g.dig("condition", "type") == "exact" }
        expect(exact_groups.length).to eq(9)
        expect(exact_groups.map { |g| g.dig("condition", "values") }.sort).to eq((1..9).map { |r| [r] })
      end

      it "round 10 uses gte condition" do
        loop_group = groups.find { |g| g.dig("condition", "type") == "gte" }
        expect(loop_group["condition"]["value"]).to eq(10)
      end

      describe "round 1 reward totals" do
        subject(:rewards) { groups.find { |g| g.dig("condition", "values") == [1] }["rewards"] }

        def qty(type, uid)
          rewards.find { |r| r["resource_type"] == type && r["resource_uid"] == uid.to_s }&.dig("quantity") || 0.0
        end

        # PairMatch: rarity3(×2)=0, rarity2(×2)=0, rarity1(×1)=20, rarity0(×1)=30 → 50
        it "equipment(1) = 50 (PairMatch only)" do
          expect(qty("equipment", 1)).to eq(50.0)
        end

        # item::10: rarity3=0, rarity2=10×2=20, rarity1=15×1=15, rarity0=20×1=20 → 55
        it "item(10) = 55 (PairMatch only)" do
          expect(qty("item", 10)).to eq(55.0)
        end

        # RoundRenewal round 1 only
        it "currency(1) = 1,000,000 (RoundRenewal only)" do
          expect(qty("currency", 1)).to eq(1_000_000.0)
        end

        it "item(80713) = 20 (RoundRenewal only)" do
          expect(qty("item", 80713)).to eq(20.0)
        end
      end

      describe "round 10 reward totals (loop)" do
        subject(:rewards) { groups.find { |g| g.dig("condition", "type") == "gte" }["rewards"] }

        def qty(type, uid)
          rewards.find { |r| r["resource_type"] == type && r["resource_uid"] == uid.to_s }&.dig("quantity") || 0.0
        end

        it "currency(1) = 900,000" do
          expect(qty("currency", 1)).to eq(900_000.0)
        end

        it "item(80713) = 6" do
          expect(qty("item", 80713)).to eq(6.0)
        end

        it "equipment(1) = 50 (PairMatch still included)" do
          expect(qty("equipment", 1)).to eq(50.0)
        end
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Treasure normalization — deterministic per-round treasure totals
  # ──────────────────────────────────────────────────────────────
  describe "Treasure normalization" do
    def build_treasure_round(round:, reward_ids:, reward_amounts:)
      {
        "TreasureRound" => round,
        "TreasureRoundSize" => [9, 5],
        "RewardId" => reward_ids,
        "RewardAmount" => reward_amounts,
        "CellCheckGoods" => {
          "ConsumeParcelId" => [80470],
          "ConsumeParcelAmount" => [250],
          "ConsumeParcelTypeStr" => ["Item"],
        },
      }
    end

    def build_treasure_reward(reward_id:, reward_ids:, reward_amounts:, reward_types:)
      [
        reward_id.to_s,
        {
          "Id" => reward_id,
          "CellUnderImageWidth" => 2,
          "CellUnderImageHeight" => 1,
          "RewardParcelId" => reward_ids,
          "RewardParcelAmount" => reward_amounts,
          "RewardParcelTypeStr" => reward_types,
        },
      ]
    end

    def build_treasure_ec(rounds:, rewards:, loop_round: 2)
      raw = {
        "season" => { "EventContentTypeStr" => ["Treasure"] },
        "treasure" => {
          "info" => [{ "LoopRound" => loop_round }],
          "round" => rounds,
          "reward" => rewards.to_h,
        },
      }
      EventContent.new(uid: "840", baql_id: "baql::events::840", raw_data_first: raw)
    end

    let(:rounds) do
      [
        build_treasure_round(round: 1, reward_ids: [1001, 1002], reward_amounts: [2, 3]),
        build_treasure_round(round: 2, reward_ids: [1002], reward_amounts: [4]),
      ]
    end
    let(:rewards) do
      [
        build_treasure_reward(reward_id: 1001, reward_ids: [80, 1], reward_amounts: [5, 1000], reward_types: %w[Item Currency]),
        build_treasure_reward(reward_id: 1002, reward_ids: [80, 999], reward_amounts: [2, 1], reward_types: %w[Item GachaGroup]),
      ]
    end
    let(:ec)     { build_treasure_ec(rounds: rounds, rewards: rewards) }
    let(:config) { ec.minigame_configs.first }
    let(:groups) { config["reward_groups"] }

    it "returns minigame_type treasure_hunt" do
      expect(config["minigame_type"]).to eq("treasure_hunt")
    end

    it "uses the first round expected cost as the legacy payment quantity" do
      expect(config["payment"]["resource_type"]).to eq("item")
      expect(config["payment"]["resource_uid"]).to eq("80470")
      expect(config["payment"]["quantity"]).to eq(6_875)
    end

    it "adds per-round payment ranges" do
      round1 = groups.find { |g| g.dig("condition", "values") == [1] }
      round2 = groups.find { |g| g.dig("condition", "type") == "gte" }

      expect(round1["payment"]).to include(
        "resource_type" => "item",
        "resource_uid" => "80470",
        "quantity_min" => 2_500,
        "quantity_expected" => 6_875,
        "quantity_max" => 11_250,
        "quantity_variable" => true,
      )
      expect(round2["payment"]).to include(
        "quantity_min" => 2_000,
        "quantity_expected" => 6_625,
        "quantity_max" => 11_250,
      )
    end

    context "when treasures fill the whole board" do
      let(:rounds) do
        [
          build_treasure_round(round: 1, reward_ids: [1001], reward_amounts: [45]),
        ]
      end
      let(:rewards) do
        [
          [
            "1001",
            {
              "Id" => 1001,
              "CellUnderImageWidth" => 1,
              "CellUnderImageHeight" => 1,
              "RewardParcelId" => [80],
              "RewardParcelAmount" => [1],
              "RewardParcelTypeStr" => %w[Item],
            },
          ],
        ]
      end

      it "marks the payment range as non-variable" do
        expect(groups.first["payment"]).to include(
          "quantity_min" => 11_250,
          "quantity_expected" => 11_250,
          "quantity_max" => 11_250,
          "quantity_variable" => false,
        )
      end
    end

    it "sums every treasure in the round by RewardAmount" do
      rewards = groups.find { |g| g.dig("condition", "values") == [1] }["rewards"]

      expect(qty(rewards, "item", 80)).to eq(16.0)
      expect(qty(rewards, "currency", 1)).to eq(2000.0)
    end

    it "filters unknown parcel types" do
      rewards = groups.find { |g| g.dig("condition", "type") == "gte" }["rewards"]

      expect(qty(rewards, "item", 80)).to eq(8.0)
      expect(rewards.map { |r| r["resource_type"] }).not_to include("gachagroup")
    end

    it "uses gte condition for the loop round" do
      group = groups.find { |g| g.dig("condition", "type") == "gte" }

      expect(group["condition"]["value"]).to eq(2)
    end

    context "when treasure key is absent" do
      subject(:ec) do
        raw = { "season" => { "EventContentTypeStr" => ["Treasure"] } }
        EventContent.new(uid: "840", baql_id: "baql::events::840", raw_data_first: raw)
      end

      it "returns an empty array" do
        expect(ec.minigame_configs).to eq([])
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # event 840 fixture data — Treasure
  # ──────────────────────────────────────────────────────────────
  describe "event 840 real data (Treasure)" do
    let(:raw)     { JSON.parse(ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/event.840.json.gz"))) }
    let(:ec)      { EventContent.new(uid: "840", baql_id: "baql::events::840", raw_data_first: raw) }
    let(:config)  { ec.minigame_configs.first }
    let(:groups)  { config["reward_groups"] }

    it "returns minigame_type treasure_hunt" do
      expect(config["minigame_type"]).to eq("treasure_hunt")
    end

    it "uses item 80470 with the first round expected cost as the legacy payment quantity" do
      expect(config["payment"]["resource_type"]).to eq("item")
      expect(config["payment"]["resource_uid"]).to eq("80470")
      expect(config["payment"]["quantity"]).to eq(8_750)
    end

    it "produces 7 groups (rounds 1-6 exact, round 7 gte)" do
      expect(groups.length).to eq(7)
      expect(groups.select { |g| g.dig("condition", "type") == "exact" }.length).to eq(6)
      expect(groups.find { |g| g.dig("condition", "type") == "gte" }["condition"]["value"]).to eq(7)
    end

    describe "round 1 reward totals" do
      let(:group) { groups.find { |g| g.dig("condition", "values") == [1] } }
      let(:rewards) { group["rewards"] }

      it "sets min/expected/max payment quantities" do
        expect(group["payment"]).to include(
          "quantity_min" => 6_250,
          "quantity_expected" => 8_750,
          "quantity_max" => 11_250,
        )
      end

      it "sums item(80473) from all treasures" do
        expect(qty(rewards, "item", 80473)).to eq(30.0)
      end

      it "sums equipment(1) from all treasures" do
        expect(qty(rewards, "equipment", 1)).to eq(220.0)
      end
    end

    describe "round 7 reward totals (loop)" do
      let(:group) { groups.find { |g| g.dig("condition", "type") == "gte" } }
      let(:rewards) { group["rewards"] }

      it "sets min/expected/max payment quantities" do
        expect(group["payment"]).to include(
          "quantity_min" => 7_250,
          "quantity_expected" => 9_250,
          "quantity_max" => 11_250,
        )
      end

      it "sums loop-round item(12)" do
        expect(qty(rewards, "item", 12)).to eq(27.0)
      end

      it "sums loop-round equipment(1)" do
        expect(qty(rewards, "equipment", 1)).to eq(40.0)
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # ClueSearch normalization — per-round multi-payment costs
  # ──────────────────────────────────────────────────────────────
  describe "ClueSearch normalization" do
    let(:raw) do
      {
        "season" => { "EventContentTypeStr" => ["ClueSearch"] },
        "clue" => {
          "round" => [
            {
              "Round" => 1,
              "IsLoop" => false,
              "ClueId" => [80804, 80805, 80805],
              "ClueCostAmount" => [3, 2, 4],
              "Reward" => {
                "RewardParcelId" => [1, 80],
                "RewardParcelAmount" => [5000, 2],
                "RewardParcelTypeStr" => %w[Currency Item],
              },
            },
            {
              "Round" => 2,
              "IsLoop" => true,
              "ClueId" => [80804, 80806],
              "ClueCostAmount" => [5, 1],
              "Reward" => {
                "RewardParcelId" => [999, 80],
                "RewardParcelAmount" => [1, 4],
                "RewardParcelTypeStr" => %w[GachaGroup Item],
              },
            },
          ],
        },
      }
    end
    let(:ec) { EventContent.new(uid: "857", baql_id: "baql::events::857", raw_data_first: raw) }
    let(:config) { ec.minigame_configs.first }
    let(:groups) { config["reward_groups"] }

    it "returns minigame_type clue_search" do
      expect(config["minigame_type"]).to eq("clue_search")
    end

    it "keeps payment as the first representative payment for legacy clients" do
      expect(config["payment"]).to include(
        "resource_type" => "item",
        "resource_uid" => "80804",
        "quantity" => 3,
      )
    end

    it "adds all first-round payments to config payments" do
      expect(config["payments"]).to contain_exactly(
        include("resource_uid" => "80804", "quantity" => 3),
        include("resource_uid" => "80805", "quantity" => 6),
      )
    end

    it "adds deterministic multi-payment ranges per round" do
      group = groups.find { |g| g.dig("condition", "values") == [1] }

      expect(group["payment"]).to include("resource_uid" => "80804", "quantity_min" => 3)
      expect(group["payments"]).to contain_exactly(
        include(
          "resource_type" => "item",
        "resource_uid" => "80804",
        "quantity_min" => 3,
        "quantity_expected" => 3,
        "quantity_max" => 3,
        "quantity_variable" => false,
      ),
      include(
        "resource_type" => "item",
        "resource_uid" => "80805",
        "quantity_min" => 6,
        "quantity_expected" => 6,
        "quantity_max" => 6,
        "quantity_variable" => false,
      ),
      )
    end

    it "normalizes round rewards and filters unknown parcel types" do
      round1_rewards = groups.find { |g| g.dig("condition", "values") == [1] }["rewards"]
      round2_rewards = groups.find { |g| g.dig("condition", "type") == "gte" }["rewards"]

      expect(qty(round1_rewards, "currency", 1)).to eq(5000.0)
      expect(qty(round1_rewards, "item", 80)).to eq(2.0)
      expect(qty(round2_rewards, "item", 80)).to eq(4.0)
      expect(round2_rewards.map { |r| r["resource_type"] }).not_to include("gachagroup")
    end

    it "uses gte condition for the loop round" do
      group = groups.find { |g| g.dig("condition", "type") == "gte" }

      expect(group["condition"]["value"]).to eq(2)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # event 857 fixture data — ClueSearch
  # ──────────────────────────────────────────────────────────────
  describe "event 857 real data (ClueSearch)" do
    let(:raw)     { JSON.parse(ActiveSupport::Gzip.decompress(File.read("spec/_fixtures/event.857.json.gz"))) }
    let(:ec)      { EventContent.new(uid: "857", baql_id: "baql::events::857", raw_data_first: raw) }
    let(:config)  { ec.minigame_configs.first }
    let(:groups)  { config["reward_groups"] }

    it "returns minigame_type clue_search" do
      expect(config["minigame_type"]).to eq("clue_search")
    end

    it "keeps the first payment as the legacy representative payment" do
      expect(config["payment"]).to include(
        "resource_type" => "item",
        "resource_uid" => "80804",
        "quantity" => 3,
      )
    end

    it "produces 7 groups (rounds 1-6 exact, round 7 gte)" do
      expect(groups.length).to eq(7)
      expect(groups.select { |g| g.dig("condition", "type") == "exact" }.map { |g| g.dig("condition", "values").first }).to eq([1, 2, 3, 4, 5, 6])
      expect(groups.find { |g| g.dig("condition", "type") == "gte" }["condition"]["value"]).to eq(7)
    end

    it "sums duplicate clue costs in round 2" do
      group = groups.find { |g| g.dig("condition", "values") == [2] }

      expect(group["payments"]).to contain_exactly(
        include("resource_uid" => "80804", "quantity_min" => 3, "quantity_expected" => 3, "quantity_max" => 3),
        include("resource_uid" => "80805", "quantity_min" => 6, "quantity_expected" => 6, "quantity_max" => 6),
        include("resource_uid" => "80808", "quantity_min" => 3, "quantity_expected" => 3, "quantity_max" => 3),
        include("resource_uid" => "80810", "quantity_min" => 3, "quantity_expected" => 3, "quantity_max" => 3),
      )
    end

    it "normalizes round 1 reward totals" do
      rewards = groups.find { |g| g.dig("condition", "values") == [1] }["rewards"]

      expect(qty(rewards, "item", 16020)).to eq(25.0)
      expect(qty(rewards, "item", 80803)).to eq(25.0)
      expect(qty(rewards, "currency", 1)).to eq(945_000.0)
    end
  end

end
