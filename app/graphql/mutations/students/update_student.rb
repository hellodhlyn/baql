# frozen_string_literal: true

module Mutations
  module Students
    class UpdateStudent < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :alt_names, [String], required: false
      argument :family_name, String, required: false
      argument :personal_name, String, required: false

      field :student, Types::StudentType, null: true

      def resolve(uid:, **attrs)
        student = find_record!(Student, uid: uid)
        student.assign_attributes(attrs.compact)
        save_record(student, student: student)
      end
    end
  end
end
