# frozen_string_literal: true

module Mutations
  module RecruitmentGroups
    class CreateRecruitmentGroup < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :recruitment_type, Types::RecruitmentTypeEnum, required: true
      argument :start_at, GraphQL::Types::ISO8601DateTime, required: true
      argument :end_at, GraphQL::Types::ISO8601DateTime, required: false
      argument :content, Types::Inputs::ContentReferenceInput, required: false
      argument :recruitments, [Types::Inputs::RecruitmentInput], required: false

      field :recruitment_group, Types::RecruitmentGroupType, null: true

      def resolve(uid:, recruitment_type:, start_at:, end_at: nil, content: nil, recruitments: [])
        group = nil
        ActiveRecord::Base.transaction do
          group = RecruitmentGroup.create!(
            uid: uid,
            baql_id: "#{RecruitmentGroup::BAQL_ID_PREFIX}#{uid}",
            recruitment_type: recruitment_type,
            start_at: start_at,
            end_at: end_at,
            content_type: content&.content_type,
            content_uid: content&.content_uid,
          )
          recruitments.each do |r|
            Recruitment.create!(
              uid: r.uid,
              baql_id: "#{Recruitment::BAQL_ID_PREFIX}#{r.uid}",
              recruitment_group_uid: group.uid,
              student_uid: r.student_uid,
              student_name: r.student_name,
              recruitment_type: r.recruitment_type,
              pickup: r.pickup,
              rerun: r.rerun,
            )
          end
        end
        { recruitment_group: group.reload, errors: [] }
      rescue ActiveRecord::RecordInvalid => e
        { recruitment_group: nil, errors: e.record.errors.full_messages }
      end
    end
  end
end
