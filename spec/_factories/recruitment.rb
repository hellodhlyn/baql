FactoryBot.define do
  factory :recruitment do
    sequence(:uid) { |n| "r-#{n}" }
    baql_id { "#{Recruitment::BAQL_ID_PREFIX}#{uid}" }
    recruitment_group_uid { FactoryBot.create(:recruitment_group).uid }
    student_uid { nil }
    student_name { "카요코" }
    recruitment_type { "usual" }
    pickup { true }
  end
end
