require "rails_helper"

RSpec.describe Student, type: :model do
  describe "#sync_images!" do
    it "syncs standing and collection images to the normalized image storage paths" do
      student = FactoryBot.build(:student, uid: "13005")

      allow(SchaleDB::V1::Images).to receive(:student_standing).with("13005").and_return("standing-image")
      allow(SchaleDB::V1::Images).to receive(:student_collection).with("13005").and_return("collection-image")
      allow(Student).to receive(:sync_image!)

      student.sync_images!

      expect(Student).to have_received(:sync_image!).with("images/students/standing/13005.webp", "standing-image")
      expect(Student).to have_received(:sync_image!).with("images/students/collection/13005.webp", "collection-image")
    end
  end

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

      allow(SchaleDB::V1::Images).to receive(:student_standing).and_return(nil)
      allow(SchaleDB::V1::Images).to receive(:student_collection).and_return(nil)

      FactoryBot.create(:item, uid: "183", name: "온전한 로혼치 사본", rarity: 4)
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
          position:     "middle",
          tactic_role:  "support",
          birthday:     Date.new(0, 3, 17),
          alt_names:     [],
          family_name:   "오니카타",
          personal_name: "카요코",
          equipments:   ["shoes", "hairpin", "necklace"],
          order:        19,
          schale_db_id: "kayoko",
        )
      end

      it "stores search tags as alternative names" do
        subject

        expect(Student.find_by(uid: "10091")).to have_attributes(
          alt_names:     ["밴즈사"],
          family_name:   "쿄야마",
          personal_name: "카즈사",
        )
      end

      it "stores the source payload in raw_data" do
        subject

        student = Student.find_by(uid: "13005")

        expect(student.raw_data["Name"]).to eq("카요코")
        expect(student.raw_data.dig("Skills", "Ex", "Name")).to eq("패닉 브링거")
        expect(student.raw_data.dig("Skills", "Public", "Name")).to eq("패닉샷")
        expect(student.raw_data.dig("Skills", "Passive", "Name")).to eq("무서운 얼굴")
        expect(student.raw_data.dig("Skills", "ExtraPassive", "Name")).to eq("어쩔 수 없네")
      end
    end

    context "when the student data already exists" do
      before { FactoryBot.create(:student, schale_db_id: "cat_lover") }

      it "updates the existing student data" do
        expect { subject }.to change { Student.find_by(uid: "13005").schale_db_id }
          .from("cat_lover").to("kayoko")
      end
    end

    context "when the skill material data does not exist" do
      it "create skill item data" do
        expect { subject }.to change { StudentSkillItem.count }.by(3)
        expect(StudentSkillItem.where(student_uid: "13005").pluck(:skill_type, :skill_level, :amount)).to contain_exactly(
          ["ex", 5, 9],
          ["normal", 8, 3],
          ["normal", 9, 8],
        )
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
        FactoryBot.create(
          :student,
          raw_data: {
            "Gear" => {
              "Name" => "아루의 엄청 귀중한 지갑",
              "TierUpMaterial" => [[5017, 150, 151]],
              "TierUpMaterialAmount" => [[4, 80, 25]],
            },
          }
        )
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
      let(:student) { FactoryBot.create(:student, raw_data: { "Gear" => {} }) }

      it "returns nil" do
        expect(student.gear).to be_nil
      end
    end

    context "when a growth item does not exist in items" do
      let(:student) do
        FactoryBot.create(
          :student,
          raw_data: {
            "Gear" => {
              "Name" => "아루의 엄청 귀중한 지갑",
              "TierUpMaterial" => [[5017, 999999]],
              "TierUpMaterialAmount" => [[4, 1]],
            },
          }
        )
      end

      it "filters the missing growth item out" do
        expect(student.gear.growth_items).to contain_exactly(
          have_attributes(gear_tier: 2, item: item_5017, amount: 4),
        )
      end
    end

    it "matches the batched GraphQL gear source" do
      students = [
        FactoryBot.create(
          :student,
          uid: "gear-source-1",
          raw_data: {
            "Gear" => {
              "Name" => "아루의 엄청 귀중한 지갑",
              "TierUpMaterial" => [[5017, 150, 151]],
              "TierUpMaterialAmount" => [[4, 80, 25]],
            },
          },
        ),
        FactoryBot.create(
          :student,
          uid: "gear-source-2",
          raw_data: {
            "Gear" => {
              "Name" => "빈 재료 테스트",
              "TierUpMaterial" => [[5017, 999999]],
              "TierUpMaterialAmount" => [[7, 1]],
            },
          },
        ),
        FactoryBot.create(:student, uid: "gear-source-empty", raw_data: { "Gear" => {} }),
      ]

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
