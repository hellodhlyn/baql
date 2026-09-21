require "rails_helper"

RSpec.describe FurnitureGroup, type: :model do
  describe "validations" do
    it "is invalid without a uid" do
      group = FactoryBot.build(:furniture_group, uid: nil)
      expect(group).not_to be_valid
    end

    it "rejects duplicate uids" do
      FactoryBot.create(:furniture_group, uid: "100")
      group = FactoryBot.build(:furniture_group, uid: "100")
      expect(group).not_to be_valid
    end
  end

  describe "translations" do
    it "scopes names to the group uid" do
      group = FactoryBot.create(:furniture_group, uid: "100", name: "모모프렌즈 카페 세트")
      other = FactoryBot.create(:furniture_group, uid: "101")

      expect(group.name).to eq("모모프렌즈 카페 세트")
      expect(group.translation_key_prefix).to eq("baql::furniture_groups::100")
      expect(other.name).to be_nil
    end
  end

  describe "associations" do
    it "returns only its own furnitures" do
      group = FactoryBot.create(:furniture_group, uid: "100")
      other_group = FactoryBot.create(:furniture_group, uid: "101")
      FactoryBot.create(:furniture, uid: "2", furniture_group_uid: group.uid)
      FactoryBot.create(:furniture, uid: "1", furniture_group_uid: group.uid)
      FactoryBot.create(:furniture, uid: "3", furniture_group_uid: other_group.uid)

      expect(group.furnitures.pluck(:uid)).to contain_exactly("1", "2")
    end
  end
end
