# frozen_string_literal: true

require "rails_helper"

RSpec.describe MiniStory, type: :model do
  describe "validations" do
    it "is valid with the default factory" do
      expect(FactoryBot.build(:mini_story)).to be_valid
    end

    it "requires a positive integer episode count" do
      zero_episode_story = FactoryBot.build(:mini_story, episode_count: 0)
      decimal_episode_story = FactoryBot.build(:mini_story, episode_count: 1.5)

      expect(zero_episode_story).not_to be_valid
      expect(zero_episode_story.errors[:episode_count]).to be_present
      expect(decimal_episode_story).not_to be_valid
      expect(decimal_episode_story.errors[:episode_count]).to be_present
    end

    it "rejects duplicate uids" do
      FactoryBot.create(:mini_story, uid: "mini-story-1")

      story = FactoryBot.build(:mini_story, uid: "mini-story-1")

      expect(story).not_to be_valid
      expect(story.errors[:uid]).to be_present
    end
  end

  describe "translations" do
    it "round-trips title translations per language" do
      story = FactoryBot.create(:mini_story, uid: "title-story")

      story.set_title("제목", "ko")
      story.set_title("タイトル", "ja")
      story.set_title("Title", "en")

      expect(story.title("ko")).to eq("제목")
      expect(story.title("ja")).to eq("タイトル")
      expect(story.title("en")).to eq("Title")
    end
  end
end

RSpec.describe MiniStorySchedule, type: :model do
  describe "validations" do
    it "requires a valid region" do
      schedule = FactoryBot.build(:mini_story_schedule, region: "tw")

      expect(schedule).not_to be_valid
      expect(schedule.errors[:region]).to be_present
    end

    it "requires released_at" do
      schedule = FactoryBot.build(:mini_story_schedule, released_at: nil)

      expect(schedule).not_to be_valid
      expect(schedule.errors[:released_at]).to be_present
    end

    it "allows only one row per mini story and region" do
      story = FactoryBot.create(:mini_story, uid: "schedule-story")
      FactoryBot.create(:mini_story_schedule, mini_story_uid: story.uid, region: "jp")

      schedule = FactoryBot.build(:mini_story_schedule, mini_story_uid: story.uid, region: "jp")

      expect(schedule).not_to be_valid
      expect(schedule.errors[:mini_story_uid]).to be_present
    end
  end
end
