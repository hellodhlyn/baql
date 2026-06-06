module Queries
  class EventContentQuery < Queries::BaseQuery
    type Types::EventContentType, null: true

    argument :uid, String, required: true
    extras [:lookahead]

    def resolve(uid:, lookahead:)
      EventContent
        .select(selected_columns_for(lookahead))
        .find_by(uid: uid)
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
