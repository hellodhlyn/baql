FactoryBot.define do
  factory :pickup do
    student_uid { "13005" }
    fallback_student_name { "카요코" }
    event_uid { "0068-from-opera-with-love" }
    pickup_type { "usual" }
    since { Time.parse("2024-08-20 02:00:00") }
    add_attribute(:until) { Time.parse("2024-09-03 02:00:00") }
    rerun { false }
  end
end
