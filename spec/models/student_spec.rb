require "rails_helper"

RSpec.describe Student, type: :model do
  describe ".sync!" do
    subject { Student.sync! }

    before do
      stub_request(:get, "https://raw.githubusercontent.com/SchaleDB/SchaleDB/main/data/kr/students.min.json")
        .to_return(body: File.read("spec/_fixtures/students.min.json"))
    end

    context "when the student data does not exist" do
      it "generates student data from the source URL" do
        subject

        expect(Student.find_by(student_id: "13005")).to have_attributes(
          name:         "카요코",
          school:       "gehenna",
          initial_tier: 2,
          attack_type:  "explosive",
          defense_type: "heavy",
          role:         "striker",
          released:     true,
          equipments:   ["shoes", "hairpin", "necklace"],
          order:        19,
        )
      end
    end

    context "when the student data already exists" do
      before { FactoryBot.create(:student, released: false) }

      it "updates the existing student data" do
        expect { subject }.to change { Student.find_by(student_id: "13005").released }.from(false).to(true)
      end
    end
  end
end
