class Raid < ApplicationRecord
  include ::Battleable

  self.inheritance_column = :_type_disabled

  RAID_TYPES = ["total_assault", "elimination", "unlimit"]
  TERRAINS   = ["indoor", "outdoor", "street"]

  validates :type, inclusion: { in: RAID_TYPES }

  # @params [Hash] filter [{ student_id: String, tier: Int }]
  def ranks(rank_after: 0, first: 20, filter: nil)
    return [] unless raid_index_jp.present? && rank_visible && type == "total_assault"
    first = 20 if first > 20

    data = Rails.cache.fetch("data::raids::#{id}::ranks", expires_in: 1.month) do
      Statics::Raids::Rank.parties(raid_index_jp)
    end

    multiclass_students_map = Student.multiclass_students.pluck(:student_id, :multiclass_id).to_h

    data.each_with_object([]) do |row, filtered|
      next if row[:rank] <= rank_after
      break filtered if filtered.size >= first

      if filter.nil?
        filtered << row
      else
        # { "10000" => [8, 8], ... }
        filter_tiers = filter.each_with_object({}) do |each, hash|
          hash[each[:student_id]] ||= []
          hash[each[:student_id]] << each[:tier]
        end

        slots = row[:parties].flatten.reject { |slot| slot[:student_id].nil? }
        matching_slots = slots.count do |slot|
          slot_student_id = slot[:student_id]
          slot_student_id = multiclass_students_map[slot_student_id] if multiclass_students_map.key?(slot_student_id)
          filter_tiers[slot_student_id].then do |tiers|
            tiers.present? && (index = tiers.index { |tier| tier >= slot[:tier].to_i }).present? && tiers.delete_at(index)
          end
        end
        filtered << row if slots.size - matching_slots == 0
      end
    end
  end
end
