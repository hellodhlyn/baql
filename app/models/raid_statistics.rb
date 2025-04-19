class RaidStatistics < ApplicationRecord
  belongs_to :raid

  def self.sync!(raid_id:)
    raid = Raid.find_by(raid_id: raid_id)
    return unless raid&.rank_visible?

    raid.defense_types.each do |defense_type|
      ranks_data = raid.ranks(defense_type: defense_type.defense_type, first: 20000)

      # { student_id => { tier => count } }
      slots_counts = {}
      assists_counts = {}
      ranks_data.each do |row|
        row[:parties].flatten.each do |slot|
          student_id = slot[:student_id]
          next if student_id.blank?

          if slot[:is_assist]
            assists_counts[student_id] ||= Hash.new(0)
            assists_counts[student_id][slot[:tier]] += 1
          else
            slots_counts[student_id] ||= Hash.new(0)
            slots_counts[student_id][slot[:tier]] += 1
          end
        end
      end

      # Transform the data and create records
      (slots_counts.keys + assists_counts.keys).uniq.each do |student_id|
        next if RaidStatistics.exists?(student_id: student_id, raid: raid, defense_type: defense_type.defense_type)
        RaidStatistics.create!(
          student_id: student_id,
          raid: raid,
          defense_type: defense_type.defense_type,
          difficulty: defense_type.difficulty,
          slots_count: slots_counts[student_id]&.values&.sum || 0,
          slots_by_tier: slots_counts[student_id] || {},
          assists_count: assists_counts[student_id]&.values&.sum || 0,
          assists_by_tier: assists_counts[student_id] || {},
        )
      end
    end
  end

  def student
    @student ||= Student.find_by_student_id(student_id)
  end

  def counts_by_tier
    super&.transform_keys(&:to_i)
  end
end
