module Queries
  class EquipmentsQuery < Queries::BaseQuery
    type [Types::EquipmentType], null: false

    argument :uids, [String], required: false

    def resolve(uids: nil)
      return Equipment.order(:uid) if uids.nil?

      Equipment.where(uid: uids)
    end
  end
end
