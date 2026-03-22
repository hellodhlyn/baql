# frozen_string_literal: true

module Types
  class QueryType < Types::Base::Object
    field :event_content,  resolver: Queries::EventContentQuery
    field :event_contents, resolver: Queries::EventContentsQuery
    field :raid, resolver: Queries::RaidQuery   # deprecated
    field :raids, resolver: Queries::RaidsQuery  # deprecated
    field :raid_schedule,  resolver: Queries::RaidScheduleQuery
    field :raid_schedules, resolver: Queries::RaidSchedulesQuery
    field :raid_boss,   resolver: Queries::RaidBossQuery
    field :raid_bosses, resolver: Queries::RaidBossesQuery
    field :student, resolver: Queries::StudentQuery
    field :students, resolver: Queries::StudentsQuery
    field :items, resolver: Queries::ItemsQuery
    field :main_stories, resolver: Queries::MainStoriesQuery
    field :recruitment_group,    resolver: Queries::RecruitmentGroupQuery
    field :recruitment_groups,   resolver: Queries::RecruitmentGroupsQuery
    field :campaign,             resolver: Queries::CampaignQuery
    field :campaigns,            resolver: Queries::CampaignsQuery
    field :joint_firing_drill,   resolver: Queries::JointFiringDrillQuery
    field :joint_firing_drills,  resolver: Queries::JointFiringDrillsQuery
    field :mini_event_content,   resolver: Queries::MiniEventContentQuery
    field :mini_event_contents,  resolver: Queries::MiniEventContentsQuery
  end
end
