# frozen_string_literal: true

module Types
  module Enums
    class ContentTypeEnum < Types::Base::Enum
      RecruitmentGroup::CONTENT_TYPES.each { |t| value t, value: t }
    end
  end
end
