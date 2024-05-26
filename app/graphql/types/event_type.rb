module Types
  class PickupType < Types::Base::Object
    field :type, String, null: false
    field :rerun, Boolean, null: false
    field :student_id, String, null: false
  end

  class VideoType < Types::Base::Object
    field :title, String, null: false
    field :youtube, String, null: false
    field :start, Int, null: true
  end

  class EventType < Types::Base::Object
    implements GraphQL::Types::Relay::Node
    implements Types::ContentInterface

    field :event_id, String, null: false
    field :type, String, null: false
    field :rerun, Boolean, null: false
    field :image_url, String, null: true
    field :videos, [VideoType], null: false
    field :pickups, [PickupType], null: false
  end
end
