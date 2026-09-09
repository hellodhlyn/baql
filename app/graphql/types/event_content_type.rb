module Types
  RESOURCE_CLASS_MAP = {
    "currency"  => -> { ::Currency },
    "item"      => -> { ::Item },
    "equipment" => -> { ::Equipment },
    "furniture" => -> { ::Furniture },
    "emblem"    => -> { ::Emblem },
  }.freeze

  module ResourceLookup
    private

    def resource_for(resource_type, resource_uid)
      klass_proc = RESOURCE_CLASS_MAP[resource_type]
      return nil unless klass_proc && resource_uid

      dataloader
        .with(Sources::RecordByUid, klass_proc.call)
        .load(resource_uid.to_s)
    end
  end

  class EventMinigamePaymentType < Types::Base::Object
    include ResourceLookup

    field :resource, Types::ResourceInterface, null: true
    field :quantity, Int, null: false

    def resource
      resource_for(object["resource_type"], object["resource_uid"])
    end
  end

  class EventMinigamePaymentRangeType < Types::Base::Object
    include ResourceLookup

    field :resource, Types::ResourceInterface, null: true
    field :quantity_min, Int, null: false
    field :quantity_expected, Int, null: false
    field :quantity_max, Int, null: false
    field :quantity_variable, Boolean, null: false

    def resource
      resource_for(object["resource_type"], object["resource_uid"])
    end
  end

  class EventMinigameRewardItemType < Types::Base::Object
    include ResourceLookup

    field :resource, Types::ResourceInterface, null: true
    field :quantity, Float, null: false

    def resource
      resource_for(object["resource_type"], object["resource_uid"])
    end
  end

  # 슬롯 조건 타입:
  #   subsequent — 모든 슬롯에 적용
  #   modulo     — slot % divisor in remainders
  #   exact      — slot in values
  #   lte        — slot <= value
  #   gte        — slot >= value
  class EventMinigameSlotConditionType < Types::Base::Object
    field :type,       String, null: false
    field :divisor,    Int,    null: true
    field :remainders, [Int],  null: true
    field :values,     [Int],  null: true
    field :value,      Int,    null: true
  end

  class EventMinigameRewardGroupType < Types::Base::Object
    field :condition, Types::EventMinigameSlotConditionType, null: false
    field :payment,   Types::EventMinigamePaymentRangeType,  null: false,
      deprecation_reason: "Use `payments` instead. This field is a legacy representative range."
    field :payments,  [Types::EventMinigamePaymentRangeType], null: false
    field :rewards,   [Types::EventMinigameRewardItemType],  null: false
  end

  class EventMinigameConfigType < Types::Base::Object
    field :minigame_type,  String,                                null: false
    field :payment,        Types::EventMinigamePaymentType,       null: false,
      deprecation_reason: "Use `payments` or `rewardGroups.payments` instead. This field is a legacy representative payment and may not describe min/expected/max semantics for variable-cost minigames."
    field :payments,       [Types::EventMinigamePaymentType],     null: false
    field :reward_groups,  [Types::EventMinigameRewardGroupType], null: false
  end

  class EventContentStageRewardType < Types::Base::Object
    include ResourceLookup

    field :resource,    Types::ResourceInterface, null: true
    field :amount,      Int,    null: false
    field :probability, String, null: false
    field :tag,         String, null: false

    def resource
      resource_for(object["reward_type"], object["reward_uid"])
    end
  end

  class EventContentStageType < Types::Base::Object
    include ResourceLookup

    field :uid,                 String,  null: false
    field :stage_index,         Int,     null: false
    field :stage_type,          String,  null: false
    field :stage_number,        String,  null: false
    field :enter_cost_resource, Types::ResourceInterface, null: true
    field :enter_cost_amount,   Int,     null: false
    field :rewards, [Types::EventContentStageRewardType], null: false

    def enter_cost_resource
      resource_for(object["enter_cost_type"], object["enter_cost_uid"])
    end
  end

  class EventContentShopResourcePurchaseTierType < Types::Base::Object
    include ResourceLookup

    field :tier_index,      Int,                      null: false
    field :start_quantity,  Int,                      null: false
    field :quantity,        Int,                      null: true
    field :unit_price,      Int,                      null: false
    field :payment_resource, Types::ResourceInterface, null: true

    def payment_resource
      resource_for(object["payment_resource_type"], object["payment_resource_uid"])
    end
  end

  class EventContentShopResourceType < Types::Base::Object
    include ResourceLookup

    field :uid,                      String,                   null: false
    field :resource,                 Types::ResourceInterface, null: true
    field :resource_amount,          Int,                      null: false
    field :payment_resource,         Types::ResourceInterface, null: true
    field :payment_resource_amount,  Int,                      null: false,
      deprecation_reason: "Use `purchaseTiers.unitPrice` instead."
    field :purchase_tiers, [Types::EventContentShopResourcePurchaseTierType], null: false
    field :shop_amount,              Int,                      null: true

    def resource
      resource_for(object["resource_type"], object["resource_uid"])
    end

    def payment_resource
      resource_for(object["payment_resource_type"], object["payment_resource_uid"])
    end
  end

  class EventContentBonusStudentType < Types::Base::Object
    field :uid, String, null: false
    field :name, String, null: false do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :role, Types::StudentType::RoleEnum, null: false

    def name(lang:)
      dataloader
        .with(Sources::StudentNameByStudent, lang)
        .load(object)
    end
  end

  class EventContentBonusType < Types::Base::Object
    include ResourceLookup

    field :student,    Types::EventContentBonusStudentType, null: true
    field :resource,   Types::ResourceInterface, null: true
    field :percentage, String, null: false

    def student
      dataloader
        .with(Sources::RecordByUid, Student)
        .load(object["student_uid"])
    end

    def resource
      resource_for(object["reward_type"], object["reward_uid"])
    end
  end

  class EventContentType < Types::Base::Object
    class RunTypeEnum < Types::Base::Enum
      value "first",     value: "first"
      value "rerun",     value: "rerun"
      value "permanent", value: "permanent"
    end

    class RegionEnum < Types::Base::Enum
      Constants::REGIONS.each { |r| value r, value: r }
    end

    field :uid,  String, null: false
    field :name, String, null: false
    field :schedules, [Types::EventContentScheduleType], null: false

    def name
      dataloader
        .with(Sources::TranslationByKey, Constants::DEFAULT_LANGUAGE)
        .load("#{object.translation_key_prefix}::name")
    end

    def schedules
      dataloader
        .with(Sources::RecordsByForeignKey, EventContentSchedule, :event_content_uid)
        .load(object.uid)
    end

    field :stages, [Types::EventContentStageType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def stages(run_type:)
      load_run(run_type).then { |run| run&.stages_payload || [] }
    end

    field :bonuses, [Types::EventContentBonusType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def bonuses(run_type:)
      load_run(run_type).then { |run| run&.bonuses_payload || [] }
    end

    field :shop_resources, [Types::EventContentShopResourceType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def shop_resources(run_type:)
      load_run(run_type).then { |run| run&.shop_resources_payload || [] }
    end

    field :minigame_configs, [Types::EventMinigameConfigType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def minigame_configs(run_type:)
      load_run(run_type).then { |run| run&.minigame_configs_payload || [] }
    end

    field :missions, [Types::EventContentMissionType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def missions(run_type:)
      dataloader
        .with(Sources::EventContentMissionsByEventUid, run_type)
        .load(object.uid)
    end

    private

    def load_run(run_type)
      dataloader
        .with(Sources::EventContentRunsByEventUid, run_type)
        .load(object.uid)
    end
  end
end
