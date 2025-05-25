class RaidStatistics < ApplicationRecord
  belongs_to :raid
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid

  def self.sync!(raid_uid:)
    raid = Raid.find_by(uid: raid_uid)
    return unless raid&.rank_visible?

    raid.defense_types.each do |defense_type|
      ranks_data = raid.ranks(defense_type: defense_type.defense_type, first: 20000)

      # { student_uid => { tier => count } }
      slots_counts = {}
      assists_counts = {}
      ranks_data.each do |row|
        row[:parties].flatten.each do |slot|
          # Keep backward compatibility for old data with `student_id`
          student_uid = (slot[:student_uid] || slot[:student_id])
          next if student_uid.blank?

          if slot[:is_assist]
            assists_counts[student_uid] ||= Hash.new(0)
            assists_counts[student_uid][slot[:tier]] += 1
          else
            slots_counts[student_uid] ||= Hash.new(0)
            slots_counts[student_uid][slot[:tier]] += 1
          end
        end
      end

      # Transform the data and create records
      (slots_counts.keys + assists_counts.keys).uniq.each do |student_uid|
        next if RaidStatistics.exists?(student_uid: student_uid, raid: raid, defense_type: defense_type.defense_type)
        RaidStatistics.create!(
          student_uid: student_uid,
          raid: raid,
          defense_type: defense_type.defense_type,
          difficulty: defense_type.difficulty,
          slots_count: slots_counts[student_uid]&.values&.sum || 0,
          slots_by_tier: slots_counts[student_uid] || {},
          assists_count: assists_counts[student_uid]&.values&.sum || 0,
          assists_by_tier: assists_counts[student_uid] || {},
        )
      end
    end
  end

  def counts_by_tier
    super&.transform_keys(&:to_i)
  end
end
