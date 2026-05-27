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
    FactoryBot.create(
      :event_content,
      uid: "854",
      raw_data_first: {
        "shop" => {
          "13" => [
            {
              "Id" => 8540000,
              "PurchaseCountLimit" => 60,
              "Goods" => [
                {
                  "ParcelId" => [19],
                  "ParcelAmount" => [1],
                  "ParcelTypeStr" => ["Currency"],
                  "ConsumeParcelId" => [4],
                  "ConsumeParcelAmount" => [5],
                  "ConsumeParcelTypeStr" => ["Currency"],
                  "ConsumeExtraAmount" => [5, 10, 15, 25, 35, 45],
                  "ConsumeExtraStep" => [10, 10, 10, 10, 10, 10],
                }
              ],
            }
          ],
        },
      },
    )
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
