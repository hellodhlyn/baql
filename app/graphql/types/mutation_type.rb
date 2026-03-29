# frozen_string_literal: true

module Types
  class MutationType < Types::Base::Object
    # RaidBoss
    field :create_raid_boss, mutation: Mutations::RaidBosses::CreateRaidBoss
    field :update_raid_boss, mutation: Mutations::RaidBosses::UpdateRaidBoss

    # RaidSchedule
    field :create_raid_schedule, mutation: Mutations::RaidSchedules::CreateRaidSchedule
    field :update_raid_schedule, mutation: Mutations::RaidSchedules::UpdateRaidSchedule

    # EventContent
    field :create_event_content, mutation: Mutations::EventContents::CreateEventContent
    field :update_event_content, mutation: Mutations::EventContents::UpdateEventContent

    # EventContentSchedule
    field :upsert_event_content_schedule, mutation: Mutations::EventContentSchedules::UpsertEventContentSchedule

    # RecruitmentGroup
    field :create_recruitment_group, mutation: Mutations::RecruitmentGroups::CreateRecruitmentGroup
    field :update_recruitment_group, mutation: Mutations::RecruitmentGroups::UpdateRecruitmentGroup

    # Recruitment
    field :create_recruitment, mutation: Mutations::Recruitments::CreateRecruitment
    field :update_recruitment, mutation: Mutations::Recruitments::UpdateRecruitment
  end
end
