module Types
  class EventShopResourceType < Types::Base::Object
    field :uid, String, null: false
    field :resource, Types::ResourceInterface, null: false
    field :resource_amount, Int, null: false
    field :payment_resource, Types::ResourceInterface, null: false
    field :payment_resource_amount, Int, null: false
    field :shop_amount, Int, null: true
  end
end
