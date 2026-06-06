require "rails_helper"

RSpec.describe Queries::StudentsQuery, type: :graphql do
  subject { Queries::StudentsQuery.new(object: nil, context: query_context, field: nil) }

  def capture_sql
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if payload[:name] == "SCHEMA"
      next if payload[:sql].match?(/\A(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/)

      queries << payload
    end

    result = yield
    [result, queries]
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  def create_students_with_favorite_items(count, offset: 0)
    count.times do |student_index|
      uid_index = offset + student_index
      student = FactoryBot.create(:student, uid: "student-#{uid_index}", name: "학생 #{uid_index}")

      2.times do |item_index|
        item = FactoryBot.create(:item, uid: "item-#{uid_index}-#{item_index}", name: "선물 #{uid_index}-#{item_index}")
        StudentFavoriteItem.create!(
          student_uid: student.uid,
          item_uid: item.uid,
          exp: 20,
          favorite_level: item_index + 1,
          favorited: item_index.even?,
        )
      end
    end
  end

  def create_students_with_recruitments(count, offset: 0)
    count.times do |student_index|
      uid_index = offset + student_index
      student = FactoryBot.create(:student, uid: "recruited-student-#{uid_index}", name: "모집 학생 #{uid_index}")
      group = FactoryBot.create(:recruitment_group, uid: "student-recruitment-group-#{uid_index}")

      FactoryBot.create(
        :recruitment,
        uid: "student-recruitment-#{uid_index}",
        recruitment_group_uid: group.uid,
        student_uid: student.uid,
        student_name: "구 모집 학생 #{uid_index}",
      )
    end
  end

  def create_students_with_skill_items(count, offset: 0)
    count.times do |student_index|
      uid_index = offset + student_index
      student = FactoryBot.create(:student, uid: "skill-student-#{uid_index}", name: "스킬 학생 #{uid_index}")
      item = FactoryBot.create(:item, uid: "skill-item-#{uid_index}", name: "스킬 재료 #{uid_index}")

      StudentSkillItem.create!(
        student_uid: student.uid,
        item_uid: item.uid,
        skill_type: "ex",
        skill_level: 1,
        amount: 2,
      )
    end
  end

  def create_students_with_gear(count, offset: 0)
    count.times do |student_index|
      uid_index = offset + student_index
      item = FactoryBot.create(:item, uid: "gear-item-#{uid_index}", name: "장비 재료 #{uid_index}")

      FactoryBot.create(
        :student,
        uid: "gear-student-#{uid_index}",
        name: "장비 학생 #{uid_index}",
        raw_data: {
          "Gear" => {
            "Name" => "애용품 #{uid_index}",
            "TierUpMaterial" => [[item.uid]],
            "TierUpMaterialAmount" => [[3]],
          },
        },
      )
    end
  end

  describe "#resolve" do
    before do
      FactoryBot.create(:student, name: "호시노(무장)", uid: "10098", multiclass_uid: "10098")
      FactoryBot.create(:student, name: "호시노(무장)", uid: "10099", multiclass_uid: "10098")
    end

    context "when uids is empty" do
      it "returns all students except for multiclass students" do
        results = subject.resolve
        expect(results.pluck(:uid)).to contain_exactly("10098")
      end
    end

    context "when uids is present" do
      it "returns students" do
        results = subject.resolve(uids: ["10098", "10099"])
        expect(results.pluck(:uid)).to contain_exactly("10098", "10099")
      end
    end
  end

  describe "favoriteItems field" do
    before do
      create_students_with_favorite_items(3)
    end

    it "batch loads favorite items without preloading items when item is not selected" do
      result, queries = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            students {
              uid
              favoriteItems {
                favoriteLevel
                favorited
                exp
              }
            }
          }
        GRAPHQL
      end

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "students").size).to eq(3)
      expect(queries.count { |payload| payload[:name] == "StudentFavoriteItem Load" }).to eq(1)
      expect(queries.none? { |payload| payload[:name] == "Item Load" }).to eq(true)

      create_students_with_favorite_items(3, offset: 3)

      _result_with_more_students, queries_with_more_students = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            students {
              uid
              favoriteItems {
                favoriteLevel
                favorited
                exp
              }
            }
          }
        GRAPHQL
      end

      expect(queries_with_more_students.count { |payload| payload[:name] == "StudentFavoriteItem Load" })
        .to eq(queries.count { |payload| payload[:name] == "StudentFavoriteItem Load" })
      expect(queries_with_more_students.count { |payload| payload[:name] == "Item Load" })
        .to eq(queries.count { |payload| payload[:name] == "Item Load" })
    end

    it "filters by favorited false" do
      result = execute_graphql(<<~GRAPHQL)
        query {
          students {
            uid
            favoriteItems(favorited: false) {
              favoriteLevel
              favorited
            }
          }
        }
      GRAPHQL

      expect(result["errors"]).to be_nil
      result.dig("data", "students").each do |student|
        expect(student["favoriteItems"]).to contain_exactly(
          a_hash_including("favoriteLevel" => 2, "favorited" => false)
        )
      end
    end
  end

  describe "recruitments field" do
    before do
      create_students_with_recruitments(3)
    end

    it "batch loads recruitments, recruitment groups, and students" do
      result, queries = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            students {
              uid
              recruitments {
                uid
                startAt
                endAt
                studentName
                student {
                  uid
                  name
                }
              }
            }
          }
        GRAPHQL
      end

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "students").size).to eq(3)
      recruited_student = result.dig("data", "students").find { |student| student["uid"] == "recruited-student-0" }
      expect(recruited_student["recruitments"]).to contain_exactly(
        a_hash_including(
          "uid" => "student-recruitment-0",
          "studentName" => "모집 학생 0",
          "student" => a_hash_including("uid" => "recruited-student-0", "name" => "모집 학생 0"),
        )
      )
      expect(queries.count { |payload| payload[:name] == "Recruitment Load" }).to eq(1)
      expect(queries.count { |payload| payload[:name] == "RecruitmentGroup Load" }).to eq(1)
      expect(queries.count { |payload| payload[:name] == "Student Load" }).to eq(2)

      create_students_with_recruitments(3, offset: 3)

      _result_with_more_students, queries_with_more_students = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            students {
              uid
              recruitments {
                uid
                startAt
                endAt
                studentName
                student {
                  uid
                  name
                }
              }
            }
          }
        GRAPHQL
      end

      expect(queries_with_more_students.count { |payload| payload[:name] == "Recruitment Load" })
        .to eq(queries.count { |payload| payload[:name] == "Recruitment Load" })
      expect(queries_with_more_students.count { |payload| payload[:name] == "RecruitmentGroup Load" })
        .to eq(queries.count { |payload| payload[:name] == "RecruitmentGroup Load" })
      expect(queries_with_more_students.count { |payload| payload[:name] == "Student Load" })
        .to eq(queries.count { |payload| payload[:name] == "Student Load" })
    end
  end

  describe "skillItems field" do
    before do
      create_students_with_skill_items(3)
    end

    it "batch loads skill items and selected items" do
      result, queries = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            students {
              uid
              skillItems {
                skillType
                skillLevel
                amount
                item {
                  uid
                  name
                }
              }
            }
          }
        GRAPHQL
      end

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "students").size).to eq(3)
      skill_student = result.dig("data", "students").find { |student| student["uid"] == "skill-student-0" }
      expect(skill_student["skillItems"]).to contain_exactly(
        a_hash_including(
          "skillType" => "ex",
          "skillLevel" => 1,
          "amount" => 2,
          "item" => a_hash_including("uid" => "skill-item-0", "name" => "스킬 재료 0"),
        )
      )
      expect(queries.count { |payload| payload[:name] == "StudentSkillItem Load" }).to eq(1)
      expect(queries.count { |payload| payload[:name] == "Item Load" }).to eq(1)

      create_students_with_skill_items(3, offset: 3)

      _result_with_more_students, queries_with_more_students = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            students {
              uid
              skillItems {
                skillType
                skillLevel
                amount
                item {
                  uid
                  name
                }
              }
            }
          }
        GRAPHQL
      end

      expect(queries_with_more_students.count { |payload| payload[:name] == "StudentSkillItem Load" })
        .to eq(queries.count { |payload| payload[:name] == "StudentSkillItem Load" })
      expect(queries_with_more_students.count { |payload| payload[:name] == "Item Load" })
        .to eq(queries.count { |payload| payload[:name] == "Item Load" })
    end
  end

  describe "gear field" do
    before do
      create_students_with_gear(3)
    end

    it "batch loads gear growth items" do
      result, queries = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            students {
              uid
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
      end

      expect(result["errors"]).to be_nil
      expect(result.dig("data", "students").size).to eq(3)
      gear_student = result.dig("data", "students").find { |student| student["uid"] == "gear-student-0" }
      expect(gear_student["gear"]).to include(
        "name" => "애용품 0",
        "growthItems" => contain_exactly(
          a_hash_including(
            "gearTier" => 2,
            "amount" => 3,
            "item" => a_hash_including("uid" => "gear-item-0", "name" => "장비 재료 0"),
          )
        ),
      )
      expect(queries.count { |payload| payload[:name] == "Item Load" }).to eq(1)

      create_students_with_gear(3, offset: 3)

      _result_with_more_students, queries_with_more_students = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            students {
              uid
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
      end

      expect(queries_with_more_students.count { |payload| payload[:name] == "Item Load" })
        .to eq(queries.count { |payload| payload[:name] == "Item Load" })
    end
  end
end
