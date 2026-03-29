# frozen_string_literal: true

module Mutations
  module Recruitments
    class CreateRecruitment < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :recruitment_group_uid, String, required: true
      argument :student_uid, String, required: false
      argument :student_name, String, required: true
      argument :recruitment_type, Types::RecruitmentTypeEnum, required: true
      argument :pickup, Boolean, required: false, default_value: true
      argument :rerun, Boolean, required: false, default_value: false

      field :recruitment, Types::RecruitmentType, null: true

      def resolve(uid:, **attrs)
        recruitment = Recruitment.new(
          **attrs,
          uid: uid,
          baql_id: "#{Recruitment::BAQL_ID_PREFIX}#{uid}",
        )
        save_record(recruitment, recruitment: recruitment)
      end
    end
  end
end
