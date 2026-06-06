# frozen_string_literal: true

module Sources
  class StudentGearByStudent < GraphQL::Dataloader::Source
    def fetch(students)
      item_uids = students.flat_map { |student| gear_item_uids(student) }.uniq
      items_by_uid = Item.where(uid: item_uids).index_by(&:uid)

      students.map { |student| build_gear(student, items_by_uid) }
    end

    private

    def gear_item_uids(student)
      materials = Array(student.raw_data&.dig("Gear", "TierUpMaterial"))
      materials.flatten.map(&:to_s)
    end

    def build_gear(student, items_by_uid)
      gear_data = student.raw_data&.dig("Gear")
      return nil if gear_data.blank? || gear_data["Name"].blank?

      materials = Array(gear_data["TierUpMaterial"])
      amounts = Array(gear_data["TierUpMaterialAmount"])

      growth_items = materials.each_with_index.flat_map do |tier_item_uids, index|
        tier_amounts = Array(amounts[index])

        Array(tier_item_uids).map.with_index do |item_uid, item_index|
          item = items_by_uid[item_uid.to_s]
          amount = tier_amounts[item_index]
          next unless item && amount

          Student::GearGrowthItem.new(gear_tier: index + 2, item: item, amount: amount)
        end
      end.compact

      Student::Gear.new(name: gear_data["Name"], growth_items: growth_items)
    end
  end
end
