# frozen_string_literal: true

module Sources
  class StudentFavoriteItemsByStudentUid < GraphQL::Dataloader::Source
    def initialize(favorited:, preload_item:)
      @favorited = favorited
      @preload_item = preload_item
    end

    def fetch(student_uids)
      records = StudentFavoriteItem.where(student_uid: student_uids)
      records = records.where(favorited: @favorited) unless @favorited.nil?
      records = records.includes(:item) if @preload_item
      records = records.order(favorite_level: :desc).to_a

      records_by_student_uid = records.group_by(&:student_uid)
      student_uids.map { |student_uid| records_by_student_uid.fetch(student_uid, []) }
    end
  end
end
