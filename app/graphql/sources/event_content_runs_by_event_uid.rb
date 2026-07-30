module Sources
  class EventContentRunsByEventUid < GraphQL::Dataloader::Source
    def initialize(run_type)
      @run_type = EventContent::RUN_TYPE_FALLBACK.fetch(run_type.to_s, run_type.to_s)
    end

    def fetch(event_content_uids)
      runs = EventContentRun
        .where(event_content_uid: event_content_uids, run_type: @run_type)
        .includes(
          { run_stages: :rewards },
          :bonuses,
          { shop_resources: :purchase_tiers },
          :minigames,
        )
        .index_by(&:event_content_uid)
      event_content_uids.map { |uid| runs[uid] }
    end
  end
end
