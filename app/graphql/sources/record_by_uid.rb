# frozen_string_literal: true

module Sources
  class RecordByUid < GraphQL::Dataloader::Source
    def initialize(model, columns: nil)
      @model = model
      @columns = columns
    end

    def fetch(uids)
      records = @model
      records = records.select(@columns) if @columns
      records = records.where(uid: uids.compact.uniq).index_by(&:uid)

      uids.map { |uid| records[uid] }
    end
  end
end
