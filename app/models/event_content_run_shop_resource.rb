class EventContentRunShopResource < ApplicationRecord
  belongs_to :event_content_run
  has_many :purchase_tiers, -> { order(:tier_index) }, class_name: "EventContentRunShopPurchaseTier", dependent: :delete_all

  def as_payload
    {
      "uid" => uid,
      "resource_type" => resource_type,
      "resource_uid" => resource_uid,
      "resource_amount" => resource_amount,
      "payment_resource_type" => payment_resource_type,
      "payment_resource_uid" => payment_resource_uid,
      "payment_resource_amount" => payment_resource_amount,
      "shop_amount" => shop_amount,
      "purchase_tiers" => purchase_tiers.map(&:as_payload),
    }
  end
end
