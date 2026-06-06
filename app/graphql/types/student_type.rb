module Types
  class StudentType < Types::Base::Object
    class RoleEnum < Types::Base::Enum
      value "striker", value: "striker"
      value "special", value: "special"
    end

    field :uid, String, null: false
    field :name, String, null: false
    field :alt_names, [String], null: false
    field :school, String, null: false
    field :initial_tier, Int, null: false
    field :attack_type, Types::Enums::AttackType, null: false
    field :defense_type, Types::Enums::DefenseType, null: false
    field :role, RoleEnum, null: false
    field :tactic_role, Types::Enums::TacticRoleType, null: false
    field :position, Types::Enums::PositionType, null: false
    field :birthday, GraphQL::Types::ISO8601Date, null: true
    field :equipments, [String], null: false
    field :release_at, GraphQL::Types::ISO8601DateTime, null: true
    field :archive_at, GraphQL::Types::ISO8601DateTime, null: true
    field :released, Boolean, null: false
    field :order, Int, null: false
    field :schale_db_id, String, null: true

    field :recruitments, [Types::RecruitmentType], null: false, extras: [:lookahead]
    def recruitments(lookahead:)
      dataloader
        .with(
          Sources::StudentRecruitmentsByStudentUid,
          preload_student: lookahead.selects?(:student) || lookahead.selects?(:student_name),
        )
        .load(object.uid)
    end

    field :skill_items, [Types::SkillItemType], null: false, extras: [:lookahead] do
      argument :skill_type, Types::Enums::StudentSkillItemTypeEnum, required: false
      argument :skill_level, Int, required: false
    end
    def skill_items(skill_type: nil, skill_level: nil, lookahead:)
      dataloader
        .with(
          Sources::StudentSkillItemsByStudentUid,
          skill_type: skill_type,
          skill_level: skill_level,
          preload_item: lookahead.selects?(:item),
        )
        .load(object.uid)
    end

    field :skills, [Types::SkillType], null: false do
      argument :skill_type, Types::Enums::StudentSkillTypeEnum, required: false
    end
    def skills(skill_type: nil)
      object.skills(skill_type: skill_type)
    end

    field :gear, Types::GearType, null: true
    def gear
      dataloader
        .with(Sources::StudentGearByStudent)
        .load(object)
    end

    field :favorite_items, [Types::FavoriteItemType], null: false, extras: [:lookahead] do
      argument :favorited, Boolean, required: false
    end
    def favorite_items(favorited: nil, lookahead:)
      dataloader
        .with(
          Sources::StudentFavoriteItemsByStudentUid,
          favorited: favorited,
          preload_item: lookahead.selects?(:item),
        )
        .load(object.uid)
    end
  end
end
