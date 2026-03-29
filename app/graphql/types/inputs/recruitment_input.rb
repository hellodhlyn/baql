# frozen_string_literal: true

module Types
  module Inputs
    class RecruitmentInput < Types::Base::InputObject
      argument :uid, String, required: true
      argument :student_uid, String, required: false
      argument :student_name, String, required: true
      argument :recruitment_type, Types::RecruitmentTypeEnum, required: true
      argument :pickup, Boolean, required: false, default_value: true
      argument :rerun, Boolean, required: false, default_value: false
    end
  end
end
