module Types
  class PickupType < Types::Base::Object
    class PickupTypeEnum < Types::Base::Enum
      ::Pickup::PICKUP_TYPES.each do |type|
        value type, value: type
      end
    end

    field :type, PickupTypeEnum, null: false
    field :rerun, Boolean, null: false
    field :student, StudentType, null: true
    field :student_name, String, null: false
    field :since, GraphQL::Types::ISO8601DateTime, null: false
    field :until, GraphQL::Types::ISO8601DateTime, null: false
  end

  class VideoType < Types::Base::Object
    field :title, String, null: false
    field :youtube, String, null: false
    field :start, Int, null: true
  end

  class StageType < Types::Base::Object
    class StageRewardType < Types::Base::Object
      field :item, ItemType, null: false
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
    field :image_url, String, null: true
    field :videos, [VideoType], null: false
    field :pickups, [PickupType], null: false
    field :stages, [StageType], null: false
  end
end
