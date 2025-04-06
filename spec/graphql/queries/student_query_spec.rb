require "rails_helper"

RSpec.describe Queries::StudentQuery, type: :graphql do
  subject { Queries::StudentQuery.new(object: nil, context: query_context, field: nil) }

  describe "#resolve" do
    before do
      FactoryBot.create(:student, name: "호시노(무장)", student_id: "10098", multiclass_id: "10098")
      FactoryBot.create(:student, name: "호시노(무장)", student_id: "10099", multiclass_id: "10098")
    end

    it "returns a student" do
      results = subject.resolve(student_id: "10098")
      expect(results.student_id).to eq("10098")
    end
  end
end
