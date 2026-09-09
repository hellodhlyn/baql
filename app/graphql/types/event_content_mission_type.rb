module Types
  class EventContentMissionCategoryEnum < Types::Base::Enum
    graphql_name "EventContentMissionCategoryEnum"

    value "daily", value: "daily"
    value "eventAchievement", value: "event_achievement"
    value "eventFixed", value: "event_fixed"
  end

  class EventContentMissionResetTypeEnum < Types::Base::Enum
    graphql_name "EventContentMissionResetTypeEnum"

    value "none", value: "none"
    value "daily", value: "daily"
  end

  class EventContentMissionDescriptionParameterType < Types::Base::Object
    graphql_name "EventContentMissionDescriptionParameter"

    field :id, Int, null: false
    field :text, String, null: false
    field :emphasized, Boolean, null: false
  end

  class EventContentMissionDescriptionType < Types::Base::Object
    graphql_name "EventContentMissionDescription"

    field :template, String, null: false
    field :parameters, [Types::EventContentMissionDescriptionParameterType], null: false
  end

  class EventContentMissionConditionType < Types::Base::Object
    graphql_name "EventContentMissionCondition"

    field :type, String, null: false
    field :count, Int, null: false
    field :parameters, [String], null: false
    field :parameter_tags, [String], null: false
  end

  class EventContentMissionRewardType < Types::Base::Object
    graphql_name "EventContentMissionReward"
    include Types::ResourceLookup

    field :resource, Types::ResourceInterface, null: false
    field :amount, Int, null: false

    def resource
      resource_for(object.fetch("resource_type"), object.fetch("resource_uid"))
    end

    def amount
      object.fetch("amount")
    end
  end

  class EventContentMissionType < Types::Base::Object
    graphql_name "EventContentMission"

    field :uid, String, null: false
    field :category, Types::EventContentMissionCategoryEnum, null: false
    field :reset_type, Types::EventContentMissionResetTypeEnum, null: false
    field :display_order, Int, null: false
    field :description, Types::EventContentMissionDescriptionType, null: false do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :condition, Types::EventContentMissionConditionType, null: false
    field :reward, Types::EventContentMissionRewardType, null: false
    field :condition_reward, Types::EventContentMissionRewardType, null: true
    field :pre_mission_uid, String, null: true
    field :completion_reference_mission_uid, String, null: true
    field :completion_reference_required_count, Int, null: false
    field :completion_extension, Boolean, null: false

    def description(lang: Constants::DEFAULT_LANGUAGE)
      object.description_for(lang)
    end

    def condition
      {
        "type" => object.condition_type,
        "count" => object.condition_count,
        "parameters" => object.condition_parameters,
        "parameter_tags" => object.condition_parameter_tags,
      }
    end

    def reward
      {
        "resource_type" => object.reward_type,
        "resource_uid" => object.reward_uid,
        "amount" => object.reward_amount,
      }
    end

    def condition_reward
      return nil unless object.condition_reward_type

      {
        "resource_type" => object.condition_reward_type,
        "resource_uid" => object.condition_reward_uid,
        "amount" => object.condition_reward_amount,
      }
    end
  end
end
