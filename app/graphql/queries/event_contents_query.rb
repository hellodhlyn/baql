module Queries
  class EventContentsQuery < Queries::BaseQuery
    type [Types::EventContentType], null: false

    argument :uids, [String], required: false
    extras [:lookahead]

    def resolve(uids: nil, lookahead:)
      scope = EventContent.select(selected_columns_for(lookahead))
      scope = scope.where(uid: uids) if uids.present?
      scope
    end

    private

    def selected_columns_for(lookahead)
      columns = [:uid, :baql_id]
      columns.concat([:raw_data_first, :raw_data_rerun]) if raw_data_selected?(lookahead)
      columns
    end

    def raw_data_selected?(lookahead)
      %i[
        raw_data_first
        raw_data_rerun
        stages
        bonuses
        shop_resources
        minigame_configs
      ].any? { |field| lookahead.selects?(field) }
    end
  end
end
