class Raid < ApplicationRecord
  include ::Battleable

  self.inheritance_column = :_type_disabled

  RAID_TYPES = ["total_assault", "elimination", "unlimit"]
  TERRAINS   = ["indoor", "outdoor", "street"]

  validates :type, inclusion: { in: RAID_TYPES }

  # @params [Hash] filter [{ student_id: String, tier: Int }]
  def ranks(rank_after: 0, count: 20, filter: nil)
    return [] unless raid_index.present? && rank_visible && type == "total_assault"
    count = 20 if count > 20

    data = Rails.cache.fetch("data::raids::#{id}::ranks", expires_in: 1.day) do
      Statics::Raids::Rank.parties(raid_index)
    end

    data.each_with_object([]) do |row, filtered|
      next if row[:rank] <= rank_after
      break filtered if filtered.size >= count

      if filter.nil?
        filtered << row
      else
        filter_tiers = filter.map { |each| [each[:student_id], each[:tier]] }.to_h
        slots = row[:parties].flatten.reject { |slot| slot[:student_id].nil? }
        matching_slots = slots.count do |slot|
          filter_tiers.delete(slot[:student_id]).then { |tier| tier.present? && tier >= slot[:tier].to_i }
        end
        filtered << row if slots.size - matching_slots <= 1
      end
    end
  end
end
