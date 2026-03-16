module Types
  class RecruitmentTypeEnum < Types::Base::Enum
    ::Recruitment::RECRUITMENT_TYPES.each do |type|
      value type, value: type
    end
  end
end
