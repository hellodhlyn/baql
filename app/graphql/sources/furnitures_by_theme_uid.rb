# frozen_string_literal: true

module Sources
  class FurnituresByThemeUid < GraphQL::Dataloader::Source
    def fetch(theme_uids)
      records = Furniture.where(in_catalog: true, theme_uid: theme_uids.compact.uniq)
        .order(:uid)
        .group_by(&:theme_uid)

      theme_uids.map { |theme_uid| records.fetch(theme_uid, []) }
    end
  end
end
