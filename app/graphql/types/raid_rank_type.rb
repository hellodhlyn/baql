module Types
  class RaidRankType < Types::Base::Object
    implements GraphQL::Types::Relay::Node

    class RaidRankFilterType < Types::Base::InputObject
      argument :student_id, String, required: true
      argument :tier, Integer, required: true
    end

    class RaidRankPartyType < Types::Base::Object
      class RaidRankPartySlotType < Types::Base::Object
        field :slot_index, Integer, null: false
        field :student, Types::StudentType, null: true
        field :tier, Integer, null: true
        field :level, Integer, null: true
        field :is_assist, Boolean, null: true

        def student
          object[:student_id].present? ? Student.find_by_student_id(object[:student_id]) : nil
        end
      end

      field :party_index, Integer, null: false
      field :slots, [RaidRankPartySlotType], null: false
    end

    field :rank, Integer, null: false
    field :score, Integer, null: false
    field :parties, [RaidRankPartyType], null: false
  end
end
