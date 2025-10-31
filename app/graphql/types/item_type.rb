module Types
  class EventStageRewardBonusType < Types::Base::Object
    field :student, StudentType, null: false
    field :ratio, String, null: false
  end

  class ItemType < Types::Base::Object
    field :uid, String, null: false
    field :name, String, null: false
    field :category, String, null: false
    field :sub_category, String, null: true
    field :rarity, Int, null: false

    field :reward_bonuses, [EventStageRewardBonusType], null: false
    def reward_bonuses
      EventStageRewardBonus.includes(:student).where(reward_resource: object)
    end
  end
end
