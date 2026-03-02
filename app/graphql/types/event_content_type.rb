module Types
  RESOURCE_CLASS_MAP = {
    "currency"  => -> { ::Currency },
    "item"      => -> { ::Item },
    "equipment" => -> { ::Equipment },
    "furniture" => -> { ::Furniture },
  }.freeze

  class EventMinigamePaymentType < Types::Base::Object
    field :resource, Types::ResourceInterface, null: true
    field :quantity, Int, null: false

    def resource
      klass_proc = RESOURCE_CLASS_MAP[object["resource_type"]]
      return nil unless klass_proc && object["resource_uid"]

      klass_proc.call.find_by(uid: object["resource_uid"])
    end
  end

  class EventMinigameRewardItemType < Types::Base::Object
    field :resource, Types::ResourceInterface, null: true
    field :quantity, Float, null: false

    def resource
      klass_proc = RESOURCE_CLASS_MAP[object["resource_type"]]
      return nil unless klass_proc && object["resource_uid"]

      klass_proc.call.find_by(uid: object["resource_uid"])
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
    field :rewards,   [Types::EventMinigameRewardItemType],  null: false
  end

  class EventMinigameConfigType < Types::Base::Object
    field :minigame_type,  String,                                null: false
    field :payment,        Types::EventMinigamePaymentType,       null: false
    field :reward_groups,  [Types::EventMinigameRewardGroupType], null: false
  end

  class EventContentScheduleType < Types::Base::Object
    field :region,   String, null: false
    field :run_type, String, null: false
    field :start_at, GraphQL::Types::ISO8601DateTime, null: false
    field :end_at,   GraphQL::Types::ISO8601DateTime, null: true
  end

  class EventContentStageRewardType < Types::Base::Object
    field :resource,    Types::ResourceInterface, null: true
    field :amount,      Int,    null: false
    field :probability, String, null: false
    field :tag,         String, null: false

    def resource
      klass_proc = RESOURCE_CLASS_MAP[object["reward_type"]]
      return nil unless klass_proc && object["reward_uid"]

      klass_proc.call.find_by(uid: object["reward_uid"])
    end
  end

  class EventContentStageType < Types::Base::Object
    field :uid,                 String,  null: false
    field :stage_index,         Int,     null: false
    field :stage_type,          String,  null: false
    field :stage_number,        String,  null: false
    field :enter_cost_resource, Types::ResourceInterface, null: true
    field :enter_cost_amount,   Int,     null: false
    field :rewards, [Types::EventContentStageRewardType], null: false

    def enter_cost_resource
      klass_proc = RESOURCE_CLASS_MAP[object["enter_cost_type"]]
      return nil unless klass_proc && object["enter_cost_uid"]

      klass_proc.call.find_by(uid: object["enter_cost_uid"])
    end
  end

  class EventContentShopResourceType < Types::Base::Object
    field :uid,                      String,                   null: false
    field :resource,                 Types::ResourceInterface, null: true
    field :resource_amount,          Int,                      null: false
    field :payment_resource,         Types::ResourceInterface, null: true
    field :payment_resource_amount,  Int,                      null: false
    field :shop_amount,              Int,                      null: true

    def resource
      klass_proc = RESOURCE_CLASS_MAP[object["resource_type"]]
      return nil unless klass_proc && object["resource_uid"]

      klass_proc.call.find_by(uid: object["resource_uid"])
    end

    def payment_resource
      klass_proc = RESOURCE_CLASS_MAP[object["payment_resource_type"]]
      return nil unless klass_proc && object["payment_resource_uid"]

      klass_proc.call.find_by(uid: object["payment_resource_uid"])
    end
  end

  class EventContentBonusType < Types::Base::Object
    field :student,    Types::StudentType, null: true
    field :resource,   Types::ResourceInterface, null: true
    field :percentage, String, null: false

    def student
      Student.find_by(uid: object["student_uid"])
    end

    def resource
      klass_proc = RESOURCE_CLASS_MAP[object["reward_type"]]
      return nil unless klass_proc && object["reward_uid"]

      klass_proc.call.find_by(uid: object["reward_uid"])
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

    field :stages, [Types::EventContentStageType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def stages(run_type:)
      object.stages(run_type: run_type)
    end

    field :bonuses, [Types::EventContentBonusType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def bonuses(run_type:)
      object.bonuses(run_type: run_type)
    end

    field :shop_resources, [Types::EventContentShopResourceType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def shop_resources(run_type:)
      object.shop_resources(run_type: run_type)
    end

    field :minigame_configs, [Types::EventMinigameConfigType], null: false do
      argument :run_type, RunTypeEnum, required: true
    end
    def minigame_configs(run_type:)
      object.minigame_configs(run_type: run_type)
    end
  end
end
