module Types
  class RaidType < Types::Base::Object
    implements GraphQL::Types::Relay::Node
    implements Types::ContentInterface

    field :raid_id, String, null: false
    field :type, String, null: false
    field :boss, String, null: false
    field :terrain, String, null: true
    field :attack_type, String, null: true
    field :defense_type, String, null: true
  end
end
