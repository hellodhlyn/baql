# frozen_string_literal: true

module Mutations
  module Students
    class UpdateStudent < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :alt_names, [String], required: false
      argument :family_name, String, required: false
      argument :name, [Types::Inputs::TranslationInput], required: false
      argument :personal_name, String, required: false

      field :student, Types::StudentType, null: true

      def resolve(uid:, name: nil, **attrs)
        student = find_record!(Student, uid: uid)

        ActiveRecord::Base.transaction do
          student.assign_attributes(attrs.compact)
          apply_name_translations(student, name)
          student.save!
        end

        { student: student.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { student: nil, errors: e.record.errors.full_messages }
      end

      private

      def apply_name_translations(student, translations)
        translations&.each do |translation|
          student.name = translation.value if translation.language == Constants::DEFAULT_LANGUAGE
          student.set_name(translation.value, translation.language)
        end
      end
    end
  end
end
