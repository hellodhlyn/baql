# frozen_string_literal: true

module Mutations
  module RecruitmentGroups
    class UpdateRecruitmentGroup < Mutations::BaseMutation
      argument :uid, String, required: true
      argument :recruitment_type, Types::RecruitmentTypeEnum, required: false
      argument :start_at, GraphQL::Types::ISO8601DateTime, required: false
      argument :end_at, GraphQL::Types::ISO8601DateTime, required: false
      argument :content, Types::Inputs::ContentReferenceInput, required: false

      field :recruitment_group, Types::RecruitmentGroupType, null: true

      def resolve(uid:, content: nil, **attrs)
        group = find_record!(RecruitmentGroup, uid: uid)
        group.assign_attributes(attrs.compact)
        group.content_type = content.content_type if content
        group.content_uid  = content.content_uid  if content
        save_record(group, recruitment_group: group)
      end
    end
  end
end
