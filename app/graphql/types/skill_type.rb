module Types
  class SkillType < Types::Base::Object
    class SkillTypeEnum < Types::Base::Enum
      value "ex", value: "ex"
      value "public", value: "public"
      value "passive", value: "passive"
      value "extra_passive", value: "extra_passive"
    end

    field :skill_type, SkillTypeEnum, null: false
    field :name, String, null: false
  end
end
