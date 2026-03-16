require "rails_helper"

RSpec.describe RecruitmentGroup, type: :model do
  describe "validations" do
    it "is invalid with an unknown content_type" do
      group = FactoryBot.build(:recruitment_group, content_type: "unknown_type", content_uid: "1")
      expect(group).not_to be_valid
      expect(group.errors[:content_type]).to be_present
    end

    it "is valid with a nil content_type" do
      group = FactoryBot.build(:recruitment_group, content_type: nil, content_uid: nil)
      expect(group).to be_valid
    end

    it "is valid with content_type 'event_content'" do
      group = FactoryBot.build(:recruitment_group, content_type: "event_content", content_uid: "100")
      expect(group).to be_valid
    end

    it "is valid with content_type 'main_story_part'" do
      group = FactoryBot.build(:recruitment_group, content_type: "main_story_part", content_uid: "1-1-1")
      expect(group).to be_valid
    end
  end

  describe "#content" do
    subject { group.content }

    context "when content_type is nil" do
      let(:group) { FactoryBot.build(:recruitment_group, content_type: nil, content_uid: nil) }

      it { is_expected.to be_nil }
    end

    context "when content_type is 'event_content'" do
      let(:event_content) { FactoryBot.create(:event_content) }
      let(:group) { FactoryBot.build(:recruitment_group, content_type: "event_content", content_uid: event_content.uid) }

      it "returns the associated EventContent" do
        expect(subject).to eq(event_content)
      end
    end

    context "when content_type is 'main_story_part'" do
      let(:main_story_part) { FactoryBot.create(:main_story_part) }
      let(:group) { FactoryBot.build(:recruitment_group, content_type: "main_story_part", content_uid: main_story_part.uid) }

      it "returns the associated MainStoryPart" do
        expect(subject).to eq(main_story_part)
      end
    end

    context "when content_uid does not match any record" do
      let(:group) { FactoryBot.build(:recruitment_group, content_type: "event_content", content_uid: "nonexistent") }

      it { is_expected.to be_nil }
    end
  end
end
