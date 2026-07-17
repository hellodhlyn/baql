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

  describe ".sync_recruitment_dates!" do
    let!(:student) { FactoryBot.create(:student, uid: "student-1", release_at: nil) }
    let!(:later_group) { FactoryBot.create(:recruitment_group, uid: "later", start_at: Time.zone.parse("2026-04-10 02:00:00")) }
    let!(:first_group) { FactoryBot.create(:recruitment_group, uid: "first", start_at: Time.zone.parse("2026-04-01 02:00:00")) }
    let!(:archive_group) { FactoryBot.create(:recruitment_group, uid: "archive", start_at: Time.zone.parse("2026-05-01 02:00:00")) }

    before do
      FactoryBot.create(:recruitment, uid: "r-later", recruitment_group_uid: later_group.uid, student_uid: student.uid, recruitment_type: "limited")
      FactoryBot.create(:recruitment, uid: "r-first", recruitment_group_uid: first_group.uid, student_uid: student.uid, recruitment_type: "usual")
      FactoryBot.create(:recruitment, uid: "r-archive", recruitment_group_uid: archive_group.uid, student_uid: student.uid, recruitment_type: "archive")
    end

    it "sets release_at from the first recruitment and archive_at from the first archive-like recruitment" do
      described_class.sync_recruitment_dates!([student.uid])

      expect(student.reload.release_at).to eq(first_group.start_at)
      expect(student.archive_at).to eq(archive_group.start_at)
    end

    it "clears dates when the student has no matching recruitments" do
      described_class.sync_recruitment_dates!([student.uid])
      Recruitment.where(student_uid: student.uid).update_all(student_uid: nil)

      described_class.sync_recruitment_dates!([student.uid])

      expect(student.reload.release_at).to be_nil
      expect(student.archive_at).to be_nil
    end
  end

  describe "#gear" do
    let!(:item_5017) { FactoryBot.create(:item, uid: "5017", name: "안티키테라 장치", rarity: 3) }
    let!(:item_150) { FactoryBot.create(:item, uid: "150", name: "네브라 디스크", rarity: 2) }
    let!(:item_151) { FactoryBot.create(:item, uid: "151", name: "아틀라스 원반", rarity: 4) }

    context "when the student has gear data" do
      let(:student) do
        FactoryBot.create(:student, gear_name: "아루의 엄청 귀중한 지갑").tap do |record|
          StudentGearGrowthItem.create!(student_uid: record.uid, item_uid: "5017", gear_tier: 2, amount: 4)
          StudentGearGrowthItem.create!(student_uid: record.uid, item_uid: "150", gear_tier: 2, amount: 80)
          StudentGearGrowthItem.create!(student_uid: record.uid, item_uid: "151", gear_tier: 2, amount: 25)
        end
      end

      it "returns parsed gear data" do
        gear = student.gear

        expect(gear.name).to eq("아루의 엄청 귀중한 지갑")
        expect(gear.growth_items).to contain_exactly(
          have_attributes(gear_tier: 2, item: item_5017, amount: 4),
          have_attributes(gear_tier: 2, item: item_150, amount: 80),
          have_attributes(gear_tier: 2, item: item_151, amount: 25),
        )
      end
    end

    context "when the gear data is empty" do
      let(:student) { FactoryBot.create(:student, gear_name: nil) }

      it "returns nil" do
        expect(student.gear).to be_nil
      end
    end

    it "matches the batched GraphQL gear source" do
      students = [
        FactoryBot.create(:student, uid: "gear-source-1", gear_name: "아루의 엄청 귀중한 지갑"),
        FactoryBot.create(:student, uid: "gear-source-2", gear_name: "빈 재료 테스트"),
        FactoryBot.create(:student, uid: "gear-source-empty", gear_name: nil),
      ]
      StudentGearGrowthItem.create!(student_uid: "gear-source-1", item_uid: "5017", gear_tier: 2, amount: 4)
      StudentGearGrowthItem.create!(student_uid: "gear-source-1", item_uid: "150", gear_tier: 2, amount: 80)
      StudentGearGrowthItem.create!(student_uid: "gear-source-1", item_uid: "151", gear_tier: 2, amount: 25)
      StudentGearGrowthItem.create!(student_uid: "gear-source-2", item_uid: "5017", gear_tier: 2, amount: 7)

      source_gears = Sources::StudentGearByStudent.new.fetch(students)

      expect(source_gears.map { |gear| serialize_gear(gear) })
        .to eq(students.map { |student| serialize_gear(student.gear) })
    end

    def serialize_gear(gear)
      return nil unless gear

      {
        name: gear.name,
        growth_items: gear.growth_items.map do |growth_item|
          {
            gear_tier: growth_item.gear_tier,
            item_uid: growth_item.item.uid,
            amount: growth_item.amount,
          }
        end,
      }
    end
  end
end
