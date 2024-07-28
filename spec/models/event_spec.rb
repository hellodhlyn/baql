require "rails_helper"

RSpec.describe Event, type: :model do
  describe ".pickups" do
    let(:event) do
      pickups = [
        {"type":"usual","rerun":false,"studentId":"10089"},
        {"type":"usual","rerun":false,"studentId":"10088","studentName":"카요코(드레스)"},
      ]
      FactoryBot.create(:event, pickups: pickups)
    end

    before do
      FactoryBot.create(:student, student_id: "10089", name: "아루(드레스)")
    end

    subject { event.pickups }

    it "returns an array of pickups" do
      expect(subject).to all(be_a(Event::Pickup))
    end

    it "returns names of students" do
      expect(subject.map(&:student_name)).to eq(["아루(드레스)", "카요코(드레스)"])
    end
  end
end
