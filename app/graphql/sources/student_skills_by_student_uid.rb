module Sources
  class StudentSkillsByStudentUid < GraphQL::Dataloader::Source
    def initialize(skill_type: nil)
      @skill_type = skill_type
    end

    def fetch(student_uids)
      records = StudentSkill.where(student_uid: student_uids)
      records = records.where(skill_type: @skill_type) if @skill_type.present?
      records_by_student_uid = records.group_by(&:student_uid)

      student_uids.map do |student_uid|
        Array(records_by_student_uid[student_uid]).sort_by do |skill|
          [StudentSkill::TYPE_ORDER.fetch(skill.skill_type), skill.uid]
        end
      end
    end
  end
end
