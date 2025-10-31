FactoryBot.define do
  factory :item, class: "Resources::Item" do
    uid { "183" }
    name { "온전한 로혼치 사본" }
    category { "material" }
    rarity { 4 }
  end
end
