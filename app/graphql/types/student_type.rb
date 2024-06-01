module Types
  class StudentType < Types::Base::Object
    field :student_id, String, null: false
    field :name, String, null: false
    field :school, String, null: false
    field :initial_tier, Int, null: false
    field :attack_type, String, null: false
    field :defense_type, String, null: false
    field :role, String, null: false
    field :equipments, String, null: true
    field :released, Boolean, null: false
    field :order, Int, null: false
  end
end
