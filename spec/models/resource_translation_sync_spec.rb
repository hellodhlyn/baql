require "rails_helper"

RSpec.describe "Resource translation sync", type: :model do
  resource_cases = [
    {
      model: Item,
      data_method: :items,
      image_method: :item_icon,
      payload: lambda do |name, description|
        {
          "resource-1" => {
            "Category" => "Material",
            "SubCategory" => nil,
            "Rarity" => "R",
            "Icon" => "item-icon",
            "Name" => name,
            "Desc" => description,
          },
        }
      end,
    },
    {
      model: Currency,
      data_method: :currencies,
      payload: lambda do |name, description|
        [
          {
            "Id" => "resource-1",
            "Rarity" => "R",
            "Icon" => nil,
            "Name" => name,
            "Desc" => description,
          },
        ]
      end,
    },
    {
      model: Equipment,
      data_method: :equipments,
      image_method: :equipment_icon,
      payload: lambda do |name, description|
        {
          "resource-1" => {
            "Category" => "Exp",
            "SubCategory" => nil,
            "Rarity" => "R",
            "Icon" => "equipment-icon",
            "Name" => name,
            "Desc" => description,
          },
        }
      end,
    },
    {
      model: Furniture,
      data_method: :furnitures,
      image_method: :furniture_icon,
      payload: lambda do |name, description|
        {
          "resource-1" => {
            "Category" => "Furniture",
            "SubCategory" => nil,
            "Rarity" => "R",
            "Tags" => [],
            "Icon" => "furniture-icon",
            "Name" => name,
            "Desc" => description,
          },
        }
      end,
    },
  ]

  resource_cases.each do |resource_case|
    describe "#{resource_case[:model]}.sync!" do
      it "stores localized names and descriptions" do
        payloads = {
          "kr" => resource_case[:payload].call("한국어 이름", "한국어 설명"),
          "jp" => resource_case[:payload].call("日本語名", "日本語の説明"),
          "en" => resource_case[:payload].call("English name", "English description"),
        }

        allow(SchaleDB::V1::Data).to receive(resource_case[:data_method]) do |lang = "kr"|
          payloads.fetch(lang)
        end
        if resource_case[:image_method]
          allow(SchaleDB::V1::Images).to receive(resource_case[:image_method]).and_return("image")
          allow(resource_case[:model]).to receive(:sync_image!)
        end

        resource_case[:model].sync!

        resource = resource_case[:model].find_by!(uid: "resource-1")
        expect(Constants::LANGUAGES.index_with { |lang| [resource.name(lang), resource.description(lang)] }).to eq(
          "ja" => ["日本語名", "日本語の説明"],
          "ko" => ["한국어 이름", "한국어 설명"],
          "en" => ["English name", "English description"],
        )
      end
    end
  end
end
