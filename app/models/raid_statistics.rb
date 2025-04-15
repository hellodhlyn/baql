class RaidStatistics < ApplicationRecord
  belongs_to :raid

  def self.sync!(student_id:)
    student = Student.find_by(student_id: student_id)
    return unless student&.released

    raids = Raid.where("since >= ?", student.release_at).where(rank_visible: true)
    raids.each do |raid|
      next if RaidStatistics.exists?(student_id: student_id, raid: raid)

      raid.defense_types.each do |defense_type|
        # { 3 => 10, 4 => 20, ... }
        counts_by_tier = raid.ranks(defense_type: defense_type.defense_type, first: 20000).map do |row|
          row[:parties].flatten.select { |slot| slot[:student_id] == student_id }.map { |slot| slot[:tier] }.max
        end.compact.tally
        next if counts_by_tier.blank?

        RaidStatistics.create!(
          student_id:     student_id,
          raid:           raid,
          defense_type:   defense_type.defense_type,
          difficulty:     defense_type.difficulty,
          counts_by_tier: counts_by_tier,
        )
      end
    end
  end

  def counts_by_tier
    super&.transform_keys(&:to_i)
  end
end
