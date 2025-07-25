require "rails_helper"

RSpec.describe Pickup, type: :model do
  describe "#fill_student" do
    subject { pickup.save! }

    let(:pickup) { FactoryBot.build(:pickup, student_uid: nil, fallback_student_name: fallback_student_name) }

    context "when student is already present" do
      let(:pickup) { FactoryBot.build(:pickup, student_uid: "13005", fallback_student_name: "카요코") }

      before do
        FactoryBot.create(:student, uid: "13005", name: "카요코")
      end

      it "does not change the student" do
        expect { subject }.not_to change { pickup.student_uid }
      end
    end

    context "when fallback_student_name is blank" do
      let(:fallback_student_name) { "" }

      it "does not set a student" do
        expect { subject }.not_to change { pickup.student_uid }
      end
    end

    context "when fallback_student_name matches an existing student" do
      let(:fallback_student_name) { "카요코" }

      before do
        FactoryBot.create(:student, uid: "13005", name: "카요코")
      end

      it "sets the student_uid to the matching student" do
        expect { subject }.to change { pickup.student_uid }.from(nil).to("13005")
      end
    end

    context "when fallback_student_name does not match any existing student" do
      let(:fallback_student_name) { "미쿠" }

      it "does not set a student" do
        expect { subject }.not_to change { pickup.student_uid }
      end
    end
  end

  describe "#student_name" do
    subject { pickup.student_name }

    context "when student is present" do
      let(:pickup) { FactoryBot.build(:pickup, student_uid: "13005", fallback_student_name: "카요코") }

      before do
        FactoryBot.create(:student, uid: "13005", name: "카요코2")
      end

      it "returns the student name" do
        expect(subject).to eq("카요코2")
      end
    end

    context "when student is not present" do
      let(:pickup) { FactoryBot.build(:pickup, student_uid: nil, fallback_student_name: "카요코") }

      it "returns the fallback student name" do
        expect(subject).to eq("카요코")
      end
    end
  end
end
