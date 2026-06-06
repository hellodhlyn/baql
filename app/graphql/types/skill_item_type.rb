module Types
  class SkillItemType < Types::Base::Object
    field :student, "Types::StudentType", null: false
    field :item, "Types::ItemType", null: false
    field :skill_type, Types::Enums::StudentSkillItemTypeEnum, null: false
    field :skill_level, Int, null: false
    field :amount, Int, null: false

    def student
      if object.association(:student).loaded?
        object.student
      else
        dataloader
          .with(Sources::RecordByUid, Student)
          .load(object.student_uid)
      end
    end

    def item
      if object.association(:item).loaded?
        object.item
      else
        dataloader
          .with(Sources::RecordByUid, Item)
          .load(object.item_uid)
      end
    end
  end
end
