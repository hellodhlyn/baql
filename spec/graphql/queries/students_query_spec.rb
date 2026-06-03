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
end
