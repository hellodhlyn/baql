module Types
  class MainStoryPartScheduleType < Types::Base::Object
    field :region,      String,                            null: false
    field :released_at, GraphQL::Types::ISO8601DateTime,   null: false
    field :confirmed,   Boolean,                           null: false
  end

  class MainStoryPartType < Types::Base::Object
    field :uid,           String, null: false
    field :name,          String, null: true
    field :sort_order,    Int,    null: false
    field :episode_start, Int,    null: true
    field :episode_end,   Int,    null: true
    field :schedules,     [Types::MainStoryPartScheduleType], null: false
  end

  class MainStoryChapterType < Types::Base::Object
    field :uid,            String, null: false
    field :name,           String, null: true
    field :chapter_number, Int,    null: false
    field :parts,          [Types::MainStoryPartType], null: false
  end

  class MainStoryVolumeType < Types::Base::Object
    field :uid,        String, null: false
    field :label,      String, null: false
    field :name,       String, null: true
    field :sort_order, Int,    null: false
    field :chapters,   [Types::MainStoryChapterType], null: false
  end
end
