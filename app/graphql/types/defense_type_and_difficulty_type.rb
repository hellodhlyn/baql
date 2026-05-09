module Types
  class DefenseTypeAndDifficultyType < Types::Base::Object
    graphql_name "DefenseTypeAndDifficulty"

    field :defense_type, Types::Enums::DefenseType, null: false
    field :difficulty, Types::Enums::DifficultyType, null: true
  end
end
