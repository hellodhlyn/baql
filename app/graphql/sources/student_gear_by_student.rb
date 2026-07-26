# frozen_string_literal: true

module Sources
  class StudentGearByStudent < GraphQL::Dataloader::Source
    def fetch(students)
      records_by_student_uid = StudentGearGrowthItem
        .where(student_uid: students.map(&:uid))
        .includes(:item)
        .group_by(&:student_uid)

      students.map { |student| build_gear(student, records_by_student_uid[student.uid]) }
    end

    private

    def build_gear(student, records)
      return nil if student.gear_name.blank?

      growth_items = Array(records).filter_map do |record|
        next unless record.item

        Student::GearGrowthItem.new(
          gear_tier: record.gear_tier,
          item: record.item,
          amount: record.amount,
        )
      end

      Student::Gear.new(name: student.gear_name, growth_items: growth_items)
    end
  end
end
