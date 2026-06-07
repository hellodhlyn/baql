require_dependency "types/event_content_type"
require_dependency "types/gacha_group_type"

module Types
  class StageEntryCostType < Types::Base::Object
    include ResourceLookup

    field :resource, Types::ResourceInterface, null: false
    field :amount, Int, null: false

    def resource
      resource_for(object["resource_type"], object["resource_uid"])
    end
  end

  class StageConditionType < Types::Base::Object
    field :type, String, null: false
    field :value, Int, null: false
  end

  class StageRewardType < Types::Base::Object
    include ResourceLookup

    field :reward_type, String, null: false
    field :resource, Types::ResourceInterface, null: true
    field :gacha_group, Types::GachaGroupType, null: true
    field :amount, Int, null: true
    field :amount_min, Int, null: true
    field :amount_max, Int, null: true
    field :probability, Float, null: true
    field :reward_tag, String, null: true

    def resource
      return nil if object["reward_type"] == "gacha_group"

      resource_for(object["reward_type"], object["reward_uid"])
    end

    def gacha_group
      return nil unless object["reward_type"] == "gacha_group"

      dataloader
        .with(Sources::RecordByUid, GachaGroup)
        .load(object["reward_uid"])
    end
  end

  class StageType < Types::Base::Object
    field :uid, String, null: false
    field :category, String, null: false
    field :stage_type, String, null: true
    field :difficulty, Int, null: true
    field :area, Int, null: true
    field :stage_number, String, null: true
    field :terrain, String, null: true
    field :level, Int, null: true
    field :name, String, null: true
    field :defense_types, [String], null: false
    field :entry_costs, [Types::StageEntryCostType], null: false
    field :star_condition, Types::StageConditionType, null: true
    field :challenge_conditions, [Types::StageConditionType], null: false

    field :rewards, [Types::StageRewardType], null: false do
      argument :region, Types::EventContentType::RegionEnum, required: false, default_value: "jp"
    end

    def name
      return nil unless object.category == "campaign"

      dataloader
        .with(Sources::TranslationByKey, Constants::DEFAULT_LANGUAGE)
        .load("#{object.translation_key_prefix}::name")
    end

    def rewards(region:)
      object.rewards(region: region)
    end
  end
end
