require "rails_helper"

RSpec.describe Queries::StudentQuery, type: :graphql do
  subject { Queries::StudentQuery.new(object: nil, context: query_context, field: nil) }

  describe "#resolve" do
    before do
      FactoryBot.create(:student, name: "호시노(무장)", uid: "10098", multiclass_uid: "10098")
      FactoryBot.create(:student, name: "호시노(무장)", uid: "10099", multiclass_uid: "10098")
    end

    it "returns a student" do
      results = subject.resolve(uid: "10098")
      expect(results.uid).to eq("10098")
    end
  end

  describe "student recruitment date fields" do
    it "returns releaseAt and archiveAt" do
      release_at = Time.zone.parse("2026-04-01 02:00:00")
      archive_at = Time.zone.parse("2026-05-01 02:00:00")
      student = FactoryBot.create(:student, uid: "student-1", release_at: release_at, archive_at: archive_at)

      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            releaseAt
            archiveAt
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student")).to eq(
        "releaseAt" => release_at.iso8601,
        "archiveAt" => archive_at.iso8601,
      )
    end
  end

  describe "student name fields" do
    it "returns localized name with Korean fallback, alternative names, family name, and personal name" do
      student = FactoryBot.create(
        :student,
        uid: "student-name-fields",
        name: "시로코",
        alt_names: ["쿠로코", "시로코 테러"],
        family_name: "스나오오카미",
        personal_name: "시로코",
      )
      student.set_name("砂狼シロコ＊テラー", "ja")

      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            koreanName: name
            japaneseName: name(lang: ja)
            englishName: name(lang: en)
            altNames
            familyName
            personalName
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student")).to eq(
        "koreanName" => "시로코",
        "japaneseName" => "砂狼シロコ＊テラー",
        "englishName" => "시로코",
        "altNames" => ["쿠로코", "시로코 테러"],
        "familyName" => "스나오오카미",
        "personalName" => "시로코",
      )
    end
  end

  describe "student club field" do
    it "returns localized club names with Korean fallback" do
      student = FactoryBot.create(:student, uid: "club-student", club: "kohshinjo68")
      Translation.create!(
        key: "baql::student_clubs::kohshinjo68::name",
        language: "ko",
        value: "흥신소 68",
      )
      Translation.create!(
        key: "baql::student_clubs::kohshinjo68::name",
        language: "ja",
        value: "便利屋68",
      )

      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            club {
              uid
              koreanName: name
              japaneseName: name(lang: ja)
              englishName: name(lang: en)
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "club")).to eq(
        "uid" => "kohshinjo68",
        "koreanName" => "흥신소 68",
        "japaneseName" => "便利屋68",
        "englishName" => "흥신소 68",
      )
    end

    it "returns null when the student has no club" do
      student = FactoryBot.create(:student, uid: "clubless-student", club: nil)

      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) { club { uid name } }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "club")).to be_nil
    end

    it "keeps a missing club translation null instead of exposing the uid" do
      student = FactoryBot.create(:student, uid: "untranslated-club-student", club: "untranslated")

      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) { club { uid name } }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "club")).to eq(
        "uid" => "untranslated",
        "name" => nil,
      )
    end
  end

  describe "student skills field" do
    let!(:student) do
      FactoryBot.create(:student, uid: "13005").tap do |record|
        StudentSkill.create!(student_uid: record.uid, skill_type: "ex", name: "패닉 브링거")
        StudentSkill.create!(student_uid: record.uid, skill_type: "public", name: "패닉샷")
        StudentSkill.create!(student_uid: record.uid, skill_type: "passive", name: "무서운 얼굴")
        StudentSkill.create!(student_uid: record.uid, skill_type: "extra_passive", name: "어쩔 수 없네")
      end
    end

    it "returns normalized skill names" do
      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            skills {
              skillType
              name
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "skills")).to eq([
        { "skillType" => "ex", "name" => "패닉 브링거" },
        { "skillType" => "public", "name" => "패닉샷" },
        { "skillType" => "passive", "name" => "무서운 얼굴" },
        { "skillType" => "extra_passive", "name" => "어쩔 수 없네" },
      ])
    end

    it "filters skills by skill_type" do
      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            skills(skillType: ex) {
              skillType
              name
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "skills")).to eq([
        { "skillType" => "ex", "name" => "패닉 브링거" },
      ])
    end

    it "returns an empty array when no skills are present" do
      student.student_skills.delete_all

      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            skills {
              skillType
              name
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "student", "skills")).to eq([])
    end

    it "returns permanent stat modifiers for the base and upgraded Hoshino passive skills" do
      StudentSkill.create!(
        student_uid: student.uid,
        uid: "CH0258_TankerPassive01",
        skill_type: "passive",
        name: "진지 구축",
        levels: [{
          "level" => 1,
          "cost" => 0,
          "stat_modifiers" => [
            { "stat" => "attack_power", "kind" => "coefficient", "value" => 1120, "activation" => "unconditional", "persistence" => "permanent" },
            { "stat" => "max_hp", "kind" => "coefficient", "value" => 1120, "activation" => "unconditional", "persistence" => "permanent" },
          ],
        }],
      )
      StudentSkill.create!(
        student_uid: student.uid,
        uid: "CH0258_TankerWeaponPassive01",
        skill_type: "passive",
        name: "진지 구축+",
        levels: [{
          "level" => 1,
          "cost" => 0,
          "stat_modifiers" => [
            { "stat" => "attack_power", "kind" => "base", "value" => 117, "activation" => "unconditional", "persistence" => "permanent" },
            { "stat" => "attack_power", "kind" => "coefficient", "value" => 1120, "activation" => "unconditional", "persistence" => "permanent" },
            { "stat" => "max_hp", "kind" => "base", "value" => 3830, "activation" => "unconditional", "persistence" => "permanent" },
            { "stat" => "max_hp", "kind" => "coefficient", "value" => 1120, "activation" => "unconditional", "persistence" => "permanent" },
          ],
        }],
      )

      result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
        query($uid: String!) {
          student(uid: $uid) {
            skills(skillType: passive, includeVariants: true) {
              uid
              levels {
                level
                statModifiers { stat kind value activation persistence }
              }
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      skills = result.dig("data", "student", "skills").index_by { |skill| skill.fetch("uid") }
      expect(skills.fetch("CH0258_TankerPassive01").dig("levels", 0, "statModifiers")).to contain_exactly(
        { "stat" => "ATTACK_POWER", "kind" => "COEFFICIENT", "value" => 1120, "activation" => "UNCONDITIONAL", "persistence" => "PERMANENT" },
        { "stat" => "MAX_HP", "kind" => "COEFFICIENT", "value" => 1120, "activation" => "UNCONDITIONAL", "persistence" => "PERMANENT" },
      )
      expect(skills.fetch("CH0258_TankerWeaponPassive01").dig("levels", 0, "statModifiers")).to contain_exactly(
        { "stat" => "ATTACK_POWER", "kind" => "BASE", "value" => 117, "activation" => "UNCONDITIONAL", "persistence" => "PERMANENT" },
        { "stat" => "ATTACK_POWER", "kind" => "COEFFICIENT", "value" => 1120, "activation" => "UNCONDITIONAL", "persistence" => "PERMANENT" },
        { "stat" => "MAX_HP", "kind" => "BASE", "value" => 3830, "activation" => "UNCONDITIONAL", "persistence" => "PERMANENT" },
        { "stat" => "MAX_HP", "kind" => "COEFFICIENT", "value" => 1120, "activation" => "UNCONDITIONAL", "persistence" => "PERMANENT" },
      )
    end
  end

  describe "student gear field" do
    let!(:item_5017) { FactoryBot.create(:item, uid: "5017", name: "안티키테라 장치", rarity: 3) }
    let!(:item_150) { FactoryBot.create(:item, uid: "150", name: "네브라 디스크", rarity: 2) }
    let!(:item_151) { FactoryBot.create(:item, uid: "151", name: "아틀라스 원반", rarity: 4) }

    context "when the student has gear data" do
      let!(:student) do
        FactoryBot.create(:student, uid: "13005", gear_name: "아루의 엄청 귀중한 지갑").tap do |record|
          StudentGearGrowthItem.create!(student_uid: record.uid, item_uid: "5017", gear_tier: 2, amount: 4)
          StudentGearGrowthItem.create!(student_uid: record.uid, item_uid: "150", gear_tier: 2, amount: 80)
          StudentGearGrowthItem.create!(student_uid: record.uid, item_uid: "151", gear_tier: 2, amount: 25)
        end
      end

      it "returns the gear name and growth items" do
        result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
          query($uid: String!) {
            student(uid: $uid) {
              gear {
                name
                growthItems {
                  gearTier
                  amount
                  item {
                    uid
                    name
                  }
                }
              }
            }
          }
        GRAPHQL

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "student", "gear")).to eq(
          {
            "name" => "아루의 엄청 귀중한 지갑",
            "growthItems" => [
              {
                "gearTier" => 2,
                "amount" => 4,
                "item" => { "uid" => "5017", "name" => "안티키테라 장치" },
              },
              {
                "gearTier" => 2,
                "amount" => 80,
                "item" => { "uid" => "150", "name" => "네브라 디스크" },
              },
              {
                "gearTier" => 2,
                "amount" => 25,
                "item" => { "uid" => "151", "name" => "아틀라스 원반" },
              },
            ],
          }
        )
      end
    end

    context "when the student does not have gear data" do
      let!(:student) { FactoryBot.create(:student, uid: "13005", gear_name: nil) }

      it "returns null" do
        result = execute_graphql(<<~GRAPHQL, variables: { uid: student.uid })
          query($uid: String!) {
            student(uid: $uid) {
              gear {
                name
              }
            }
          }
        GRAPHQL

        expect(result["errors"]).to be_nil
        expect(result.dig("data", "student", "gear")).to be_nil
      end
    end
  end
end
