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

  def build_fortune_gacha_ec(shop:)
    raw = {
      "season" => { "EventContentTypeStr" => ["FortuneGachaShop"] },
      "fortune_gacha" => { "shop" => shop },
    }
    EventContent.new(uid: "851", baql_id: "baql::events::851", raw_data_first: raw)
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
    #   - Entry A (prob=100): GachaGroup 300001×1, currency "1" ×1000  → currency: 0.1×1000=100
    #   - Entry B (prob=200): GachaGroup 300002×2, currency "1" ×500   → currency: 0.2×500=100
    #   - Entry C (prob=700): item "80" ×5                              → item: 0.7×5=3.5
    #   GachaGroup rewards are filtered out
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

    subject(:ec) { build_fortune_gacha_ec(shop: [entry_a, entry_b, entry_c]) }
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

        it "filters out GachaGroup rewards" do
          types = rewards.map { |r| r["resource_type"] }
          expect(types).not_to include("gachagroup")
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
end
