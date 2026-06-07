require_dependency "types/event_content_type"

module Types
  class GachaGroupItemType < Types::Base::Object
    include ResourceLookup

    field :resource, Types::ResourceInterface, null: true
    field :chance, Float, null: true
    field :amount_min, Int, null: true
    field :amount_max, Int, null: true

    def resource
      resource_for(object["resource_type"], object["resource_uid"])
    end
  end

  class GachaGroupType < Types::Base::Object
    field :uid, String, null: false
    field :recursive, Boolean, null: false
    field :reward_all, Boolean, null: false

    field :items, [Types::GachaGroupItemType], null: false do
      argument :region, Types::EventContentType::RegionEnum, required: false, default_value: "jp"
    end

    def items(region:)
      object.items(region: region)
    end
  end
end
