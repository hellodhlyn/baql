require "rails_helper"

RSpec.describe Queries::StudentsQuery, type: :graphql do
  subject { Queries::StudentsQuery.new(object: nil, context: query_context, field: nil) }

  describe "#resolve" do
    before do
      FactoryBot.create(:student, name: "호시노(무장)", uid: "10098", multiclass_uid: "10098")
      FactoryBot.create(:student, name: "호시노(무장)", uid: "10099", multiclass_uid: "10098")
    end

    context "when student_ids is empty" do
      it "returns all students except for multiclass students" do
        results = subject.resolve
        expect(results.pluck(:uid)).to contain_exactly("10098")
      end
    end

    context "when student_ids is present" do
      it "returns students" do
        results = subject.resolve(student_ids: ["10098", "10099"])
        expect(results.pluck(:uid)).to contain_exactly("10098", "10099")
      end
    end
  end
end
