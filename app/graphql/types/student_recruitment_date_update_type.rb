# frozen_string_literal: true

module Types
  class StudentRecruitmentDateUpdateType < Types::Base::Object
    field :uid, String, null: false
    field :recruitment_group_uid, String, null: false
    field :before_release_at, GraphQL::Types::ISO8601DateTime, null: true
    field :after_release_at, GraphQL::Types::ISO8601DateTime, null: true
    field :before_archive_at, GraphQL::Types::ISO8601DateTime, null: true
    field :after_archive_at, GraphQL::Types::ISO8601DateTime, null: true
  end
end
