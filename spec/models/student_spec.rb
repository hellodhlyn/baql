require "rails_helper"

RSpec.describe Student, type: :model do
  describe ".all_without_multiclass" do
    before do
      FactoryBot.create(:student, uid: "10098", multiclass_uid: "10098")
      FactoryBot.create(:student, uid: "10099", multiclass_uid: "10098")
    end

    it "returns all students except for multiclass students" do
      expect(Student.all.pluck(:uid)).to contain_exactly("10098", "10099")
      expect(Student.all_without_multiclass.pluck(:uid)).to contain_exactly("10098")
    end
  end

  describe ".sync!" do
    subject { Student.sync! }

    before do
      stub_request(:get, "https://schaledb.com/data/kr/students.min.json")
        .to_return(body: File.read("spec/_fixtures/students.min.json"))
    end

    context "when the student data does not exist" do
      it "generates student data from the source URL" do
        subject

        expect(Student.find_by(uid: "13005")).to have_attributes(
          name:         "카요코",
          school:       "gehenna",
          initial_tier: 2,
          attack_type:  "explosive",
          defense_type: "heavy",
          role:         "striker",
          equipments:   ["shoes", "hairpin", "necklace"],
          order:        19,
          schale_db_id: "kayoko",
        )
      end
    end

    context "when the student data already exists" do
      before { FactoryBot.create(:student, schale_db_id: "cat_lover") }

      it "updates the existing student data" do
        expect { subject }.to change { Student.find_by(uid: "13005").schale_db_id }
          .from("cat_lover").to("kayoko")
      end
    end
  end

  describe "#released" do
    subject { student.released }

    let(:student) { FactoryBot.build(:student, release_at: release_at) }

    context "when the release_at is nil" do
      let(:release_at) { nil }
      it { is_expected.to be_falsey }
    end

    context "when the release_at is in the past" do
      let(:release_at) { 1.day.ago }
      it { is_expected.to be_truthy }
    end

    context "when the release_at is in the future" do
      let(:release_at) { 1.day.from_now }
      it { is_expected.to be_falsey }
    end
  end
end
