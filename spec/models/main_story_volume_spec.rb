require "rails_helper"

RSpec.describe MainStoryVolume, type: :model do
  describe "validations" do
    it "is valid with the default factory" do
      expect(FactoryBot.build(:main_story_volume)).to be_valid
    end

    it "requires a season" do
      volume = FactoryBot.build(:main_story_volume, season: nil)

      expect(volume).not_to be_valid
      expect(volume.errors[:season]).to be_present
    end
  end
end
