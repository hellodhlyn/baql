module Maintenance
  class GlScheduleShift
    ScheduleUpdate = Data.define(:label, :identifier, :changes)
    StudentReleaseUpdate = Data.define(:uid, :recruitment_group_uid, :before, :after)
    Result = Data.define(:dry_run, :total_rows, :schedule_updates, :student_release_updates)

    TARGETS = [
      {
        label: "event_content_schedules",
        model: EventContentSchedule,
        columns: [:start_at, :end_at],
        relation: ->(cutoff) {
          EventContentSchedule
            .where(region: "gl")
            .where("start_at >= ?", cutoff)
            .order(:start_at, :event_content_uid, :run_type)
        },
        identify: ->(row) { "event_content_uid=#{row.event_content_uid}, run_type=#{row.run_type}" },
      },
      {
        label: "raid_schedules",
        model: RaidSchedule,
        columns: [:start_at, :end_at],
        relation: ->(cutoff) {
          RaidSchedule
            .where(region: "gl")
            .where("start_at >= ?", cutoff)
            .order(:start_at, :raid_type, :season_index)
        },
        identify: ->(row) { "uid=#{row.uid}, raid_type=#{row.raid_type}, season_index=#{row.season_index}" },
      },
      {
        label: "campaigns",
        model: Campaign,
        columns: [:start_at, :end_at],
        relation: ->(cutoff) {
          Campaign
            .where(region: "gl")
            .where("start_at >= ?", cutoff)
            .order(:start_at, :uid)
        },
        identify: ->(row) { "uid=#{row.uid}, category=#{row.category.join(",")}" },
      },
      {
        label: "joint_firing_drill_schedules",
        model: JointFiringDrillSchedule,
        columns: [:start_at, :end_at],
        relation: ->(cutoff) {
          JointFiringDrillSchedule
            .where(region: "gl")
            .where("start_at >= ?", cutoff)
            .order(:start_at, :drill_uid)
        },
        identify: ->(row) { "drill_uid=#{row.drill_uid}" },
      },
      {
        label: "mini_event_content_schedules",
        model: MiniEventContentSchedule,
        columns: [:start_at, :end_at],
        relation: ->(cutoff) {
          MiniEventContentSchedule
            .where(region: "gl")
            .where("start_at >= ?", cutoff)
            .order(:start_at, :mini_event_content_uid, :occurrence)
        },
        identify: ->(row) { "mini_event_content_uid=#{row.mini_event_content_uid}, occurrence=#{row.occurrence}" },
      },
      {
        label: "main_story_part_schedules",
        model: MainStoryPartSchedule,
        columns: [:released_at],
        relation: ->(cutoff) {
          MainStoryPartSchedule
            .where(region: "gl")
            .where("released_at >= ?", cutoff)
            .order(:released_at, :part_uid)
        },
        identify: ->(row) { "part_uid=#{row.part_uid}" },
      },
      {
        label: "recruitment_groups",
        model: RecruitmentGroup,
        columns: [:start_at, :end_at],
        relation: ->(cutoff) {
          RecruitmentGroup
            .where("start_at >= ?", cutoff)
            .order(:start_at, :uid)
        },
        identify: ->(row) { "uid=#{row.uid}, recruitment_type=#{row.recruitment_type}" },
      },
    ].freeze

    attr_reader :cutoff, :shift_by, :dry_run

    def initialize(cutoff:, shift_by:, dry_run:)
      @cutoff = cutoff
      @shift_by = shift_by
      @dry_run = dry_run
    end

    def call
      schedule_updates = []
      student_release_updates = []
      shifted_recruitment_group_uids = []
      total_rows = 0

      ActiveRecord::Base.transaction do
        TARGETS.each do |target|
          rows = target[:relation].call(cutoff).to_a
          total_rows += rows.size

          shifted_recruitment_group_uids.concat(rows.map(&:uid)) if target[:model] == RecruitmentGroup

          rows.each do |row|
            row.lock!
            changes = shift_row!(row, target[:columns])
            schedule_updates << ScheduleUpdate.new(
              label: target[:label],
              identifier: target[:identify].call(row),
              changes: changes,
            )
          end
        end

        student_release_updates.concat(
          sync_student_release_dates!(shifted_recruitment_group_uids.uniq),
        )

        raise ActiveRecord::Rollback if dry_run
      end

      Result.new(
        dry_run: dry_run,
        total_rows: total_rows,
        schedule_updates: schedule_updates,
        student_release_updates: student_release_updates,
      )
    end

    private

    def shift_row!(row, columns)
      changes = {}

      columns.each do |column|
        before = row.public_send(column)
        after = before.present? ? before + shift_by : before
        row.public_send("#{column}=", after)
        changes[column] = [before, after]
      end

      row.save!
      changes
    end

    def sync_student_release_dates!(recruitment_group_uids)
      return [] if recruitment_group_uids.empty?

      recruitments_by_student_uid = Recruitment
        .where(recruitment_group_uid: recruitment_group_uids)
        .where.not(student_uid: nil)
        .group_by(&:student_uid)

      recruitments_by_student_uid.filter_map do |student_uid, recruitments|
        student = Student.lock.find_by(uid: student_uid)
        next unless student

        first_recruitment_group = RecruitmentGroup
          .joins(:recruitments)
          .where(recruitments: { student_uid: student.uid })
          .order(:start_at, :uid)
          .first
        next unless first_recruitment_group

        shifted_group_uids = recruitments.map(&:recruitment_group_uid)
        next unless shifted_group_uids.include?(first_recruitment_group.uid)
        next if student.release_at == first_recruitment_group.start_at

        before = student.release_at
        student.update!(release_at: first_recruitment_group.start_at)
        StudentReleaseUpdate.new(
          uid: student.uid,
          recruitment_group_uid: first_recruitment_group.uid,
          before: before,
          after: first_recruitment_group.start_at,
        )
      end
    end
  end
end
