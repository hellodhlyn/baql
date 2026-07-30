require "rails_helper"

RSpec.describe "EventContent bonuses", type: :graphql do
  it "exposes a limited student reference even before the JP profile release" do
    student = FactoryBot.create(
      :student,
      uid: "jp-unreleased",
      name: "미공개 학생",
      role: "striker",
      jp_release_at: 1.day.from_now,
    )
    event = FactoryBot.create(:event_content, uid: "900")
    run = EventContentRun.create!(
      event_content_uid: event.uid,
      run_type: "first",
      source_event_content_uid: 900,
      position: 0,
    )
    EventContentRunBonus.create!(
      event_content_run: run,
      student_uid: student.uid,
      reward_type: "item",
      reward_uid: "90000",
      percentage: "0.25",
      position: 0,
    )

    result = execute_graphql(<<~GRAPHQL)
      query {
        hiddenProfile: student(uid: "jp-unreleased") { uid }
        eventContent(uid: "900") {
          bonuses(runType: first) {
            percentage
            student { uid name role }
          }
        }
      }
    GRAPHQL

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "hiddenProfile")).to be_nil
    expect(result.dig("data", "eventContent", "bonuses")).to eq([
      {
        "percentage" => "0.25",
        "student" => { "uid" => student.uid, "name" => "미공개 학생", "role" => "striker" },
      },
    ])
    expect(Types::EventContentBonusStudentType.fields.keys).to contain_exactly("uid", "name", "role")
  end
end
