module Types
  class PickupType < Types::Base::Object
    class PickupTypeEnum < Types::Base::Enum
      ::Event::PICKUP_TYPES.each do |type|
        value type, value: type
      end
    end

    field :type, PickupTypeEnum, null: false
    field :rerun, Boolean, null: false
    field :student, StudentType, null: true
    field :student_name, String, null: false
  end

  class VideoType < Types::Base::Object
    field :title, String, null: false
    field :youtube, String, null: false
    field :start, Int, null: true
  end

  class EventType < Types::Base::Object
    implements GraphQL::Types::Relay::Node
    implements Types::ContentInterface

    class EventTypeEnum < Types::Base::Enum
      ::Event::EVENT_TYPES.each do |type|
        value type, value: type
      end
    end

    field :event_id, String, null: false
    field :type, EventTypeEnum, null: false
    field :rerun, Boolean, null: false
    field :image_url, String, null: true
    field :videos, [VideoType], null: false
    field :pickups, [PickupType], null: false
  end
end
