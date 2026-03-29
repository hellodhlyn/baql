# frozen_string_literal: true

module Types
  module Inputs
    class ContentReferenceInput < Types::Base::InputObject
      argument :content_type, Types::Enums::ContentTypeEnum, required: true
      argument :content_uid,  String,                        required: true
    end
  end
end
