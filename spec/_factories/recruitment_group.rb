FactoryBot.define do
  factory :recruitment_group do
    sequence(:uid) { |n| "20260307#{n.to_s.rjust(2, "0")}" }
    baql_id { "#{RecruitmentGroup::BAQL_ID_PREFIX}#{uid}" }
    start_at { Time.parse("2026-03-04 02:00:00") }
    end_at { Time.parse("2026-03-18 02:00:00") }
    recruitment_type { "limited" }
    content_type { nil }
    content_uid { nil }
  end
end
