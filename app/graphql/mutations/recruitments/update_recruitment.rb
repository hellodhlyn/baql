# frozen_string_literal: true

module Mutations
  module Recruitments
    class UpdateRecruitment < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :recruitment_group_uid, String, required: false
      argument :student_uid, String, required: false
      argument :student_name, String, required: false
      argument :recruitment_type, Types::RecruitmentTypeEnum, required: false
      argument :pickup, Boolean, required: false
      argument :rerun, Boolean, required: false

      field :recruitment, Types::RecruitmentType, null: true

      def resolve(uid:, **attrs)
        recruitment = find_record!(Recruitment, uid: uid)
        recruitment.assign_attributes(attrs.compact)
        save_record(recruitment, recruitment: recruitment)
      end
    end
  end
end
