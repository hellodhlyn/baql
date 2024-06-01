require "rails_helper"

RSpec.describe Student, type: :model do
  describe ".sync!" do
    subject { Student.sync! }

    before do
      stub_request(:get, "https://raw.githubusercontent.com/SchaleDB/SchaleDB/main/data/kr/students.min.json")
        .to_return(body: File.read("spec/_fixtures/students.min.json"))
    end

    it "synchronizes student data from the source URL" do
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
end
