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

    # Campaign
    field :create_campaign, mutation: Mutations::Campaigns::CreateCampaign
    field :update_campaign, mutation: Mutations::Campaigns::UpdateCampaign

    # JointFiringDrill
    field :create_joint_firing_drill, mutation: Mutations::JointFiringDrills::CreateJointFiringDrill
    field :update_joint_firing_drill, mutation: Mutations::JointFiringDrills::UpdateJointFiringDrill

    # JointFiringDrillSchedule
    field :upsert_joint_firing_drill_schedule, mutation: Mutations::JointFiringDrillSchedules::UpsertJointFiringDrillSchedule
  end
end
