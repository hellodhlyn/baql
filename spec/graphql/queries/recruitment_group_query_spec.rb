require "rails_helper"

RSpec.describe Queries::RecruitmentGroupQuery, type: :graphql do
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

  def query(uid)
    <<~GRAPHQL
      query {
        recruitmentGroup(uid: "#{uid}") {
          uid
          startAt
          endAt
          contentType
          contentUid
          recruitments {
            uid
            recruitmentType
            pickup
            studentName
          }
        }
      }
      GRAPHQL
  end

  def create_recruitment_groups_with_students(count, offset: 0)
    count.times do |group_index|
      uid_index = offset + group_index
      group = FactoryBot.create(:recruitment_group, uid: "group-#{uid_index}")

      2.times do |student_index|
        student = FactoryBot.create(:student, uid: "student-#{uid_index}-#{student_index}")
        FactoryBot.create(
          :recruitment,
          recruitment_group_uid: group.uid,
          student_uid: student.uid,
          student_name: "학생 #{uid_index}-#{student_index}",
        )
      end
    end
  end

  describe "find by uid" do
    let!(:group) do
      FactoryBot.create(:recruitment_group,
        uid: "some-event",
        content_type: "event_content",
        content_uid: "834")
    end

    before do
      FactoryBot.create(:recruitment, recruitment_group_uid: group.uid, student_name: "카요코", recruitment_type: "limited", pickup: true)
    end

    it "returns the matching group" do
      result = execute_graphql(query("some-event"))
      data = result["data"]["recruitmentGroup"]
      expect(data["uid"]).to eq("some-event")
      expect(data["contentType"]).to eq("event_content")
      expect(data["contentUid"]).to eq("834")
    end

    it "returns recruitments" do
      result = execute_graphql(query("some-event"))
      recruitments = result["data"]["recruitmentGroup"]["recruitments"]
      expect(recruitments).to contain_exactly(
        a_hash_including("studentName" => "카요코", "recruitmentType" => "limited", "pickup" => true)
      )
    end
  end

  describe "when no group exists for uid" do
    it "returns null" do
      result = execute_graphql(query("nonexistent"))
      expect(result["data"]["recruitmentGroup"]).to be_nil
    end
  end

  describe "studentName resolution" do
    let(:group) { FactoryBot.create(:recruitment_group, uid: "some-event-2", content_type: "event_content", content_uid: "835") }

    context "when student is linked" do
      before do
        FactoryBot.create(:student, uid: "13005", name: "카요코(최신)")
        FactoryBot.create(:recruitment, recruitment_group_uid: group.uid, student_uid: "13005", student_name: "카요코(구버전)")
      end

      it "returns the student's current name" do
        result = execute_graphql(query("some-event-2"))
        student_name = result["data"]["recruitmentGroup"]["recruitments"].first["studentName"]
        expect(student_name).to eq("카요코(최신)")
      end
    end

    context "when student is not linked" do
      before do
        FactoryBot.create(:recruitment, recruitment_group_uid: group.uid, student_uid: nil, student_name: "미공개학생")
      end

      it "returns student_name" do
        result = execute_graphql(query("some-event-2"))
        student_name = result["data"]["recruitmentGroup"]["recruitments"].first["studentName"]
        expect(student_name).to eq("미공개학생")
      end
    end
  end

  describe "recruitmentGroups query" do
    before do
      create_recruitment_groups_with_students(2)
    end

    it "uses preloaded recruitments, students, and recruitment groups" do
      result, queries = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            recruitmentGroups {
              uid
              recruitments {
                since
                until
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
      expect(result.dig("data", "recruitmentGroups").size).to eq(2)
      expect(queries.count { |payload| payload[:name] == "Recruitment Load" }).to eq(1)
      expect(queries.count { |payload| payload[:name] == "Student Load" }).to eq(1)
      expect(queries.count { |payload| payload[:name] == "RecruitmentGroup Load" }).to eq(1)

      create_recruitment_groups_with_students(2, offset: 2)

      _result_with_more_groups, queries_with_more_groups = capture_sql do
        execute_graphql(<<~GRAPHQL)
          query {
            recruitmentGroups {
              uid
              recruitments {
                since
                until
                student {
                  uid
                  name
                }
              }
            }
          }
        GRAPHQL
      end

      expect(queries_with_more_groups.count { |payload| payload[:name] == "Recruitment Load" })
        .to eq(queries.count { |payload| payload[:name] == "Recruitment Load" })
      expect(queries_with_more_groups.count { |payload| payload[:name] == "Student Load" })
        .to eq(queries.count { |payload| payload[:name] == "Student Load" })
      expect(queries_with_more_groups.count { |payload| payload[:name] == "RecruitmentGroup Load" })
        .to eq(queries.count { |payload| payload[:name] == "RecruitmentGroup Load" })
    end
  end
end
