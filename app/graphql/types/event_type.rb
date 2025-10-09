module Types
  class VideoType < Types::Base::Object
    field :title, String, null: false
    field :youtube, String, null: false
    field :start, Int, null: true
  end

  class StageType < Types::Base::Object
    class StageItemEventBonusType < Types::Base::Object
      field :student, StudentType, null: false
      field :ratio, Float, null: false
    end

    class StageItemType < Types::Base::Object
      field :item_id, String, null: false
      field :name, String, null: false
      field :image_id, String, null: false
      field :event_bonuses, [StageItemEventBonusType], null: false
    end

    class StageRewardType < Types::Base::Object
      field :item, StageItemType, null: false
      field :amount, Float, null: false
    end

    field :name, String, null: false
    field :difficulty, Int, null: false
    field :index, String, null: false
    field :entry_ap, Int, null: true
    field :rewards, [StageRewardType], null: false
  end

  class EventType < Types::Base::Object
    implements GraphQL::Types::Relay::Node
    implements Types::ContentInterface

    class EventTypeEnum < Types::Base::Enum
      ::Event::EVENT_TYPES.each do |type|
        value type, value: type
      end
    end

    field :type, EventTypeEnum, null: false
    field :rerun, Boolean, null: false
    field :endless, Boolean, null: false
    field :image_url, String, null: true
    field :videos, [VideoType], null: false
    field :pickups, [Types::PickupType], null: false
    def pickups
      # Use preloaded associations if available
      if object.association(:pickups).loaded?
        object.pickups.sort_by(&:id)
      else
        object.pickups.order(:id)
      end
    end

    field :stages, [StageType], null: false
  end
end
