require "rails_helper"

RSpec.describe "EventContent shop resources", type: :graphql do
  let!(:pyroxene) do
    Currency.create!(uid: "4", baql_id: "baql::currencies::4", rarity: 4, raw_data: {}).tap do |currency|
      currency.set_name("청휘석", "ko")
    end
  end

  let!(:ticket) do
    Currency.create!(uid: "19", baql_id: "baql::currencies::19", rarity: 1, raw_data: {}).tap do |currency|
      currency.set_name("연합 작전 티켓", "ko")
    end
  end

  let!(:event_content) do
    FactoryBot.create(:event_content, uid: "854").tap do |event|
      run = EventContentRun.create!(event_content_uid: event.uid, run_type: "first", source_event_content_uid: 854, position: 0)
      shop = EventContentRunShopResource.create!(
        event_content_run: run,
        uid: "8540000",
        resource_type: "currency",
        resource_uid: "19",
        resource_amount: 1,
        payment_resource_type: "currency",
        payment_resource_uid: "4",
        payment_resource_amount: 5,
        shop_amount: 60,
        position: 0,
      )
      [5, 10, 15, 25, 35, 45].each_with_index do |price, index|
        EventContentRunShopPurchaseTier.create!(
          event_content_run_shop_resource: shop,
          tier_index: index,
          start_quantity: index * 10 + 1,
          quantity: 10,
          unit_price: price,
          payment_resource_type: "currency",
          payment_resource_uid: "4",
        )
      end
    end
  end

  let(:query) do
    <<~GRAPHQL
      query($uid: String!) {
        eventContent(uid: $uid) {
          shopResources(runType: first) {
            uid
            paymentResourceAmount
            purchaseTiers {
              tierIndex
              startQuantity
              quantity
              unitPrice
              paymentResource {
                uid
              }
            }
          }
        }
      }
    GRAPHQL
  end

  it "exposes tiered shop prices without removing the legacy amount field" do
    result = execute_graphql(query, variables: { uid: event_content.uid })
    shop_resource = result.dig("data", "eventContent", "shopResources").first

    expect(result["errors"]).to be_nil
    expect(shop_resource["paymentResourceAmount"]).to eq(5)
    expect(shop_resource["purchaseTiers"]).to eq([
      { "tierIndex" => 0, "startQuantity" => 1, "quantity" => 10, "unitPrice" => 5, "paymentResource" => { "uid" => "4" } },
      { "tierIndex" => 1, "startQuantity" => 11, "quantity" => 10, "unitPrice" => 10, "paymentResource" => { "uid" => "4" } },
      { "tierIndex" => 2, "startQuantity" => 21, "quantity" => 10, "unitPrice" => 15, "paymentResource" => { "uid" => "4" } },
      { "tierIndex" => 3, "startQuantity" => 31, "quantity" => 10, "unitPrice" => 25, "paymentResource" => { "uid" => "4" } },
      { "tierIndex" => 4, "startQuantity" => 41, "quantity" => 10, "unitPrice" => 35, "paymentResource" => { "uid" => "4" } },
      { "tierIndex" => 5, "startQuantity" => 51, "quantity" => 10, "unitPrice" => 45, "paymentResource" => { "uid" => "4" } },
    ])
  end
end
