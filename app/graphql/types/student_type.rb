module Types
  class StudentType < Types::Base::Object
    class RoleEnum < Types::Base::Enum
      value "striker", value: "striker"
      value "special", value: "special"
    end

    field :student_id, String, null: false
    field :name, String, null: false
    field :school, String, null: false
    field :initial_tier, Int, null: false
    field :attack_type, Types::Enums::AttackType, null: false
    field :defense_type, Types::Enums::DefenseType, null: false
    field :role, RoleEnum, null: false
    field :equipments, [String], null: false
    field :released, Boolean, null: false
    field :order, Int, null: false
  end
end
