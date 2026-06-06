module Types
  class DefenseTypeSetType < Types::Base::Object
    graphql_name "DefenseTypeSet"

    field :defense_types, [Types::Enums::DefenseType], null: false
    field :difficulty, Types::Enums::DifficultyType, null: true
  end
end
