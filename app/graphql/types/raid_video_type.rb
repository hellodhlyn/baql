module Types
  class RaidVideoType < Types::Base::Object
    implements GraphQL::Types::Relay::Node

    field :title, String, null: false
    field :score, Integer, null: false
    field :youtube_id, String, null: false
    field :thumbnail_url, String, null: false
    field :published_at, String, null: false
  end
end
