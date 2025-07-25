require "rails_helper"

RSpec.describe "Contents Query", type: :graphql do
  describe "contents query" do
    let!(:event1) { FactoryBot.create(:event, uid: "event-1", since: 5.weeks.ago, until: 4.weeks.ago) }
    let!(:event2) { FactoryBot.create(:event, uid: "event-2", since: 3.weeks.ago, until: 2.weeks.ago) }
    let!(:raid1) { FactoryBot.create(:raid, uid: "raid-1", since: 2.weeks.ago, until: 1.week.ago) }
    let!(:raid2) { FactoryBot.create(:raid, uid: "raid-2", since: 1.week.from_now, until: 2.weeks.from_now) }

    query = <<~GRAPHQL
      query($untilAfter: ISO8601DateTime, $sinceBefore: ISO8601DateTime, $contentIds: [String!]) {
        contents(untilAfter: $untilAfter, sinceBefore: $sinceBefore, contentIds: $contentIds) {
          edges {
            node {
              uid name
            }
          }
        }
      }
    GRAPHQL

    let(:variables) { {} }

    subject { execute_graphql(query, variables: variables)["data"]["contents"]["edges"].map { |edge| edge["node"] } }

    context "when no arguments are provided" do
      it "returns all contents" do
        expect(subject.map { |node| node["uid"] }).to eq(["event-1", "event-2", "raid-1", "raid-2"])
      end
    end

    context "when untilAfter is provided" do
      let(:variables) { { untilAfter: 10.days.ago.iso8601 } }

      it "returns contents until the provided time" do
        expect(subject.map { |node| node["uid"] }).to eq(["raid-1", "raid-2"])
      end
    end

    context "when sinceBefore is provided" do
      let(:variables) { { sinceBefore: 2.weeks.ago.iso8601 } }

      it "returns contents since the provided time" do
        expect(subject.map { |node| node["uid"] }).to eq(["event-1", "event-2"])
      end
    end

    context "when contentIds is provided" do
      let(:variables) { { contentIds: ["event-1", "raid-1"] } }

      it "returns contents with the provided IDs" do
        expect(subject.map { |node| node["uid"] }).to eq(["event-1", "raid-1"])
      end
    end
  end
end
