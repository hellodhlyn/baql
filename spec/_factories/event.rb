FactoryBot.define do
  factory :event do
    uid { "0068-from-opera-with-love" }
    name { "0068 오페라로부터 사랑을 담아서!" }
    type { "event" }
    rerun { false }
    since { Time.parse("2024-08-20 02:00:00") }
    add_attribute(:until) { Time.parse("2024-09-03 02:00:00") }
  end
end
