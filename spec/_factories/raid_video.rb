FactoryBot.define do
  factory :raid_video do
    title { "Blue Archive 総力戦 シロ&クロ 室内 12345678" }
    score { 12345678 }
    youtube_id { "dQw4w9WgXcQ" }
    thumbnail_url { "https://example.com/thumbnail.jpg" }
    published_at { "2025-02-25T10:00:00Z" }
    raid_type { "total_assault" }
    raid_boss { "shirokuro" }
    raid_terrain { "indoor" }
    raid_defense_type { "special" }
  end
end
