# frozen_string_literal: true

module Sources
  class StudentSkillItemsByStudentUid < GraphQL::Dataloader::Source
    def initialize(skill_type:, skill_level:, preload_item:)
      @skill_type = skill_type
      @skill_level = skill_level
      @preload_item = preload_item
    end

    def fetch(student_uids)
      records = StudentSkillItem.where(student_uid: student_uids.compact.uniq)
      records = records.where(skill_type: @skill_type) if @skill_type.present?
      records = records.where(skill_level: @skill_level) if @skill_level.present?
      records = records.includes(:item) if @preload_item
      records = records.order(skill_type: :asc, skill_level: :asc).to_a

      records_by_student_uid = records.group_by(&:student_uid)
      student_uids.map { |student_uid| records_by_student_uid.fetch(student_uid, []) }
    end
  end
end
