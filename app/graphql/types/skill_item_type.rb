module Types
  class SkillItemType < Types::Base::Object
    class SkillTypeEnum < Types::Base::Enum
      value "normal", value: "normal"
      value "ex", value: "ex"
    end

    field :student, "Types::StudentType", null: false
    field :item, "Types::ItemType", null: false
    field :skill_type, SkillTypeEnum, null: false
    field :skill_level, Int, null: false
    field :amount, Int, null: false
  end
end
