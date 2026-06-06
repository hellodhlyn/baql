# frozen_string_literal: true

module Sources
  class StudentRecruitmentsByStudentUid < GraphQL::Dataloader::Source
    def initialize(preload_student:)
      @preload_student = preload_student
    end

    def fetch(student_uids)
      records = Recruitment
        .includes(:recruitment_group)
        .where(student_uid: student_uids.compact.uniq)
      records = records.includes(:student) if @preload_student
      records = records.order(:id).to_a

      records_by_student_uid = records.group_by(&:student_uid)
      student_uids.map { |student_uid| records_by_student_uid.fetch(student_uid, []) }
    end
  end
end
