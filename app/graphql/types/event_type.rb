module Types
  class VideoType < Types::Base::Object
    field :title, String, null: false
    field :youtube, String, null: false
    field :start, Int, null: true
  end

  class LegacyStageType < Types::Base::Object
    class StageItemEventBonusType < Types::Base::Object
      field :student, StudentType, null: false
      field :ratio, Float, null: false
    end

    class StageItemType < Types::Base::Object
      field :item_id, String, null: false
      field :name, String, null: false
      field :image_id, String, null: false
      field :event_bonuses, [StageItemEventBonusType], null: false
    end

    class StageRewardType < Types::Base::Object
      field :item, StageItemType, null: false
      field :amount, Float, null: false
    end

    field :name, String, null: false
    field :difficulty, Int, null: false
    field :index, String, null: false
    field :entry_ap, Int, null: true
    field :rewards, [StageRewardType], null: false
  end

  class EventType < Types::Base::Object
    implements GraphQL::Types::Relay::Node
    implements Types::ContentInterface

    class EventTypeEnum < Types::Base::Enum
      ::Event::EVENT_TYPES.each do |type|
        value type, value: type
      end
    end

    field :type, EventTypeEnum, null: false
    field :rerun, Boolean, null: false
    field :endless, Boolean, null: false
    field :image_url, String, null: true
    field :videos, [VideoType], null: false
    field :pickups, [Types::PickupType], null: false
    def pickups
      # Use preloaded associations if available
      if object.association(:pickups).loaded?
        object.pickups.sort_by(&:id)
      else
        object.pickups.order(:id)
      end
    end

    field :legacy_stages, [LegacyStageType], null: false, deprecation_reason: "Use `stages` instead"

    field :stages, [EventStageType], null: false do
      argument :difficulty, Int, required: false
    end
    def stages(difficulty: nil)
      query = object.stages.includes(:rewards)
      query = query.where(difficulty: difficulty) if difficulty.present?

      # Custom sorting: 1) by difficulty, 2) by index with number strings sorted numerically
      query.to_a.sort_by do |stage|
        # First sort by difficulty
        difficulty_sort = stage.difficulty

        # Then sort by index with number indices first, then alphabetically
        index_sort = if stage.index.match?(/^\d+$/)
          [0, stage.index.to_i]
        else
          [1, stage.index]
        end

        [difficulty_sort, index_sort]
      end
    end

    field :shop_resources, [EventShopResourceType], null: false
    def shop_resources
      object.shop_resources.includes(:resource, :payment_resource).order(id: :asc)
    end
  end
end
