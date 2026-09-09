module Sources
  class EventContentMissionsByEventUid < GraphQL::Dataloader::Source
    def initialize(run_type)
      @run_type = EventContent::RUN_TYPE_FALLBACK.fetch(run_type.to_s, run_type.to_s)
    end

    def fetch(event_content_uids)
      runs = EventContentRun
        .where(event_content_uid: event_content_uids, run_type: @run_type)
        .pluck(:id, :event_content_uid)
      run_ids = runs.map(&:first)
      missions_by_run_id = EventContentRunMission
        .where(event_content_run_id: run_ids)
        .ordered
        .group_by(&:event_content_run_id)

      runs_by_event_uid = runs.to_h do |run_id, event_content_uid|
        [event_content_uid, missions_by_run_id.fetch(run_id, [])]
      end
      event_content_uids.map { |uid| runs_by_event_uid.fetch(uid, []) }
    end
  end
end
