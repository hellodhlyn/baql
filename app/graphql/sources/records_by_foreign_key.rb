# frozen_string_literal: true

module Sources
  class RecordsByForeignKey < GraphQL::Dataloader::Source
    def initialize(model, foreign_key, order: nil)
      @model = model
      @foreign_key = foreign_key
      @order = order
    end

    def fetch(keys)
      records = @model.where(@foreign_key => keys.compact.uniq)
      records = records.order(@order) if @order

      records_by_key = records.group_by { |record| record.public_send(@foreign_key) }
      keys.map { |key| records_by_key.fetch(key, []) }
    end
  end
end
