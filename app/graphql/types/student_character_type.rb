module Types
  class StudentCharacterType < Types::Base::Object
    field :uid, String, null: false
    field :student_variants, [Types::StudentVariantType], null: false

    def student_variants
      dataloader
        .with(
          Sources::RecordsByForeignKey,
          Student,
          :character_group_uid,
          order: { order: :asc, uid: :asc },
        )
        .load(object.uid)
        .then do |students|
          students
            .map(&:student_variant_uid)
            .uniq
            .map { |uid| StudentVariant.new(uid:) }
        end
    end
  end
end
