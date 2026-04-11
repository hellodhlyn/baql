module Types
  class SkillItemType < Types::Base::Object
    field :student, "Types::StudentType", null: false
    field :item, "Types::ItemType", null: false
    field :skill_type, Types::Enums::StudentSkillItemTypeEnum, null: false
    field :skill_level, Int, null: false
    field :amount, Int, null: false
  end
end
