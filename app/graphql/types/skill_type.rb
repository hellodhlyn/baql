module Types
  class SkillType < Types::Base::Object
    field :skill_type, Types::Enums::StudentSkillTypeEnum, null: false
    field :name, String, null: false
  end
end
