module Types
  class RaidRankType < Types::Base::Object
    implements GraphQL::Types::Relay::Node

    class RaidRankFilterType < Types::Base::InputObject
      argument :uid, String, required: true
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
          # Keep backward compatibility for old data with `student_id`
          student_uid = object[:student_uid] || object[:student_id]
          student_uid.present? ? Student.find_by_uid(student_uid) : nil
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
