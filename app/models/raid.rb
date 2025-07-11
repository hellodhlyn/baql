class Raid < ApplicationRecord
  include ::Battleable

  self.inheritance_column = :_type_disabled

  RAID_TYPES   = ["total_assault", "elimination", "unlimit"]
  TERRAINS     = ["indoor", "outdoor", "street"]
  DIFFICULTIES = ["normal", "hard", "very_hard", "hardcore", "extreme", "insane", "torment", "lunatic"]

  validates :type, inclusion: { in: RAID_TYPES }

  ### Defense types
  DefenseType = Data.define(:defense_type, :difficulty)

  json_array_attr :defense_types, DefenseType

  # Old `defense_type` column is deprecated. Use this method for backward compatibility.
  def defense_type
    defense_types.first.defense_type
  end

  # @params [Hash] include_students [{ uid: String, tier: Int }]
  # @params [Hash] exclude_students [{ uid: String, tier: Int }]
  def ranks(defense_type: nil, rank_after: nil, rank_before: nil, first: 20, include_students: nil, exclude_students: nil)
    return [] if type == "elimination" && (defense_type.blank? || defense_types.none? { |type| type.defense_type == defense_type })
    return [] if raid_index_jp.blank? || !rank_visible || type == "unlimit"
    rank_after = 0 if rank_after.blank? && rank_before.blank?

    data = Rails.cache.fetch("data::raids::#{id}::#{defense_type || "total_assault"}::ranks", expires_in: 1.month) do
      if type == "elimination"
        Statics::Raids::Rank.elimination_parties(raid_index_jp, defense_type)
      else
        Statics::Raids::Rank.total_assault_parties(raid_index_jp)
      end
    end

    if include_students.blank? && exclude_students.blank?
      if rank_before.present?
        last_index = data.find_index { |row| row[:rank] >= rank_before }
        return [] if last_index.nil? || last_index == 0
        start_index = [last_index - first, 0].max
        return data.slice(start_index, last_index - start_index)
      else
        first_index = data.find_index { |row| row[:rank] > rank_after }
        return [] if first_index.nil?
        return data.slice(first_index, first)
      end
    end

    # Convert multiclass students to their main id
    multiclass_students_map = Student.multiclass_students.pluck(:uid, :multiclass_uid).to_h
    include_students&.map! do |filter|
      student_uid = filter[:uid]
      filter[:uid] = multiclass_students_map[student_uid] || student_uid
      filter
    end
    exclude_students&.map! do |filter|
      student_uid = filter[:uid]
      filter[:uid] = multiclass_students_map[student_uid] || student_uid
      filter
    end

    matched_rows = []
    data.reverse! if rank_before.present?
    data.each do |row|
      next if rank_before.present? ? row[:rank] >= rank_before : row[:rank] <= rank_after

      slots = row[:parties].flatten.map! do |slot|
        # Keep backward compatibility for old data with `student_id`
        student_uid = slot[:student_uid] || slot[:student_id]
        slot[:student_uid] = multiclass_students_map[student_uid] || student_uid
        slot
      end

      if include_students.present?
        # Check if all include_students are present in the row
        next unless include_students.all? do |filter|
          slots.any? { |slot| slot[:student_uid] == filter[:uid] && slot[:tier].to_i >= filter[:tier] }
        end
      end
      if exclude_students.present?
        # Check if any exclude_students are present in the row
        next if exclude_students.any? do |filter|
          slots.any? { |slot| slot[:student_uid] == filter[:uid] && slot[:tier].to_i <= filter[:tier] }
        end
      end

      matched_rows << row
      break matched_rows if matched_rows.size >= first
    end

    rank_before.present? ? matched_rows.reverse : matched_rows
  end
end
