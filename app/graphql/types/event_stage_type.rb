module Types
  class EventStageRewardType < Types::Base::Object
    field :reward_type, String, null: false
    field :reward_uid, String, null: false
    field :reward_requirement, String, null: true
    field :amount, Int, null: false
    field :amount_min, Int, null: true
    field :amount_max, Int, null: true
    field :chance, String, null: true

    field :item, ItemType, null: true
  end

  class EventStageType < Types::Base::Object
    field :uid, String, null: false
    field :name, String, null: false
    field :difficulty, Int, null: false
    field :index, String, null: false
    field :entry_ap, Int, null: false

    field :event, EventType, null: false
    field :rewards, [EventStageRewardType], null: false do
      argument :reward_type, String, required: false
    end
    def rewards(reward_type: nil)
      query = object.rewards
      query = query.where(reward_type: reward_type) if reward_type.present?
      query
    end
  end
end
