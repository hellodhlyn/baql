module Types
  class StudentVariantType < Types::Base::Object
    field :uid, String, null: false
    field :is_multiclass, Boolean, null: false
    field :primary_student, Types::StudentType, null: false
    field :students, [Types::StudentType], null: false

    def is_multiclass
      load_students.then { |students| students.many? }
    end

    def primary_student
      load_students.then(&:first)
    end

    def students
      load_students
    end

    private

    def load_students
      dataloader
        .with(
          Sources::RecordsByForeignKey,
          Student,
          :student_variant_uid,
          order: { order: :asc, uid: :asc },
        )
        .load(object.uid)
    end
  end
end
