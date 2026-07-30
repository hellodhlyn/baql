class EventContentRunShopPurchaseTier < ApplicationRecord
  belongs_to :event_content_run_shop_resource

  def as_payload
    {
      "tier_index" => tier_index,
      "start_quantity" => start_quantity,
      "quantity" => quantity,
      "unit_price" => unit_price,
      "payment_resource_type" => payment_resource_type,
      "payment_resource_uid" => payment_resource_uid,
    }
  end
end
