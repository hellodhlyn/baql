require "rails_helper"

RSpec.describe Types::RaidType, type: :graphql do
  let(:raid) { FactoryBot.create(:raid, uid: SecureRandom.uuid) }

  describe "#statistics" do
    query = <<~GRAPHQL
      query($uid: String!, $defenseType: Defense!) {
        raid(uid: $uid) {
          statistics(defenseType: $defenseType) {
            defenseType
            slotsCount
          }
        }
      }
    GRAPHQL

    subject { execute_graphql(query, variables: { uid: raid.uid, defenseType: "light" }) }

    context "when multiple defense types exist" do
      before do
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "light", slots_count: 100)
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "heavy", slots_count: 300)
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "elastic", slots_count: 200)
      end

      it "returns statistics for the given defense type" do
        expect(subject["data"]["raid"]["statistics"].count).to eq(1)
        expect(subject["data"]["raid"]["statistics"].first["defenseType"]).to eq("light")
      end
    end

    context "when multiple students exist" do
      before do
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "light", slots_count: 100)
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "light", slots_count: 300)
        FactoryBot.create(:raid_statistics, raid: raid, defense_type: "light", slots_count: 200)
      end

      it "sorted by slots_count" do
        expect(subject["data"]["raid"]["statistics"].first["slotsCount"]).to eq(300)
        expect(subject["data"]["raid"]["statistics"].last["slotsCount"]).to eq(100)
      end
    end
  end

  describe "#videos" do
    query = <<~GRAPHQL
      query($uid: String!, $after: String, $first: Int, $sort: VideoSortEnum) {
        raid(uid: $uid) {
          videos(after: $after, first: $first, sort: $sort) {
            edges {
              node {
                title
                score
                youtubeId
                publishedAt
              }
              cursor
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
          }
        }
      }
    GRAPHQL

    subject { execute_graphql(query, variables: { uid: raid.uid }) }

    context "when videos exist for the raid" do
      before do
        FactoryBot.create(:raid_video,
          raid_type: raid.type,
          raid_boss: raid.boss,
          raid_terrain: raid.terrain,
          title: "Video 1",
          score: 12345678,
          published_at: "2025-02-25T10:00:00Z"
        )
        FactoryBot.create(:raid_video,
          raid_type: raid.type,
          raid_boss: raid.boss,
          raid_terrain: raid.terrain,
          title: "Video 2",
          score: 87654321,
          published_at: "2025-02-26T10:00:00Z"
        )
        FactoryBot.create(:raid_video,
          raid_type: raid.type,
          raid_boss: raid.boss,
          raid_terrain: raid.terrain,
          title: "Video 3",
          score: 55555555,
          published_at: "2025-02-27T10:00:00Z"
        )
      end

      it "returns videos ordered by published_at desc" do
        result = subject["data"]["raid"]["videos"]
        expect(result["edges"].count).to eq(3)
        expect(result["edges"].first["node"]["title"]).to eq("Video 3")
        expect(result["edges"].last["node"]["title"]).to eq("Video 1")
      end

      it "returns correct video data" do
        result = subject["data"]["raid"]["videos"]
        first_video = result["edges"].first["node"]

        expect(first_video["title"]).to eq("Video 3")
        expect(first_video["score"]).to eq(55555555)
        expect(first_video["youtubeId"]).to eq("dQw4w9WgXcQ")
        expect(first_video["publishedAt"]).to eq("2025-02-27T10:00:00Z")
      end

      it "returns pagination info" do
        result = subject["data"]["raid"]["videos"]
        page_info = result["pageInfo"]

        expect(page_info["hasNextPage"]).to be false
        expect(page_info["hasPreviousPage"]).to be false
        expect(page_info["startCursor"]).to be_present
        expect(page_info["endCursor"]).to be_present
      end
    end

    context "when no videos exist for the raid" do
      it "returns empty edges" do
        result = subject["data"]["raid"]["videos"]
        expect(result["edges"]).to be_empty
      end

      it "returns correct pagination info for empty result" do
        result = subject["data"]["raid"]["videos"]
        page_info = result["pageInfo"]

        expect(page_info["hasNextPage"]).to be false
        expect(page_info["hasPreviousPage"]).to be false
        expect(page_info["startCursor"]).to be_nil
        expect(page_info["endCursor"]).to be_nil
      end
    end

    context "when videos exist for different raids" do
      let(:other_raid) { FactoryBot.create(:raid, uid: SecureRandom.uuid, type: "elimination", boss: "binah", terrain: "outdoor") }

      before do
        # Create videos for the current raid
        FactoryBot.create(:raid_video,
          raid_type: raid.type,
          raid_boss: raid.boss,
          raid_terrain: raid.terrain,
          title: "Current Raid Video"
        )

        # Create videos for a different raid
        FactoryBot.create(:raid_video,
          raid_type: other_raid.type,
          raid_boss: other_raid.boss,
          raid_terrain: other_raid.terrain,
          title: "Other Raid Video"
        )
      end

      it "only returns videos for the current raid" do
        result = subject["data"]["raid"]["videos"]
        expect(result["edges"].count).to eq(1)
        expect(result["edges"].first["node"]["title"]).to eq("Current Raid Video")
      end
    end

    context "with pagination parameters" do
      before do
        5.times do |i|
          FactoryBot.create(:raid_video,
            raid_type: raid.type,
            raid_boss: raid.boss,
            raid_terrain: raid.terrain,
            title: "Video #{i + 1}",
            published_at: (5 - i).days.ago.iso8601
          )
        end
      end

      context "with first parameter" do
        subject { execute_graphql(query, variables: { uid: raid.uid, first: 2 }) }

        it "limits the number of results" do
          result = subject["data"]["raid"]["videos"]
          expect(result["edges"].count).to eq(2)
        end

        it "indicates there are more pages" do
          result = subject["data"]["raid"]["videos"]
          expect(result["pageInfo"]["hasNextPage"]).to be true
        end
      end

      context "with after parameter" do
        let(:first_result) { execute_graphql(query, variables: { uid: raid.uid, first: 2 }) }
        let(:cursor) { first_result["data"]["raid"]["videos"]["pageInfo"]["endCursor"] }
        subject { execute_graphql(query, variables: { uid: raid.uid, after: cursor, first: 2 }) }

        it "returns results after the cursor" do
          result = subject["data"]["raid"]["videos"]
          expect(result["edges"].count).to eq(2)
          expect(result["edges"].first["node"]["title"]).to eq("Video 3")
        end
      end
    end

    context "with sorting options" do
      before do
        FactoryBot.create(:raid_video,
          raid_type: raid.type,
          raid_boss: raid.boss,
          raid_terrain: raid.terrain,
          title: "Video 1",
          score: 10000000,
          published_at: "2025-02-25T10:00:00Z"
        )
        FactoryBot.create(:raid_video,
          raid_type: raid.type,
          raid_boss: raid.boss,
          raid_terrain: raid.terrain,
          title: "Video 2",
          score: 20000000,
          published_at: "2025-02-26T10:00:00Z"
        )
        FactoryBot.create(:raid_video,
          raid_type: raid.type,
          raid_boss: raid.boss,
          raid_terrain: raid.terrain,
          title: "Video 3",
          score: 15000000,
          published_at: "2025-02-27T10:00:00Z"
        )
      end

      context "when sorting by published_at desc (default)" do
        subject { execute_graphql(query, variables: { uid: raid.uid, sort: "PUBLISHED_AT_DESC" }) }

        it "returns videos ordered by published_at desc" do
          result = subject["data"]["raid"]["videos"]
          expect(result["edges"].count).to eq(3)
          expect(result["edges"].first["node"]["title"]).to eq("Video 3")
          expect(result["edges"].last["node"]["title"]).to eq("Video 1")
        end
      end

      context "when sorting by score desc" do
        subject { execute_graphql(query, variables: { uid: raid.uid, sort: "SCORE_DESC" }) }

        it "returns videos ordered by score desc" do
          result = subject["data"]["raid"]["videos"]
          expect(result["edges"].count).to eq(3)
          expect(result["edges"].first["node"]["title"]).to eq("Video 2")
          expect(result["edges"].second["node"]["title"]).to eq("Video 3")
          expect(result["edges"].last["node"]["title"]).to eq("Video 1")
        end

        it "returns correct scores in descending order" do
          result = subject["data"]["raid"]["videos"]
          expect(result["edges"].first["node"]["score"]).to eq(20000000)
          expect(result["edges"].second["node"]["score"]).to eq(15000000)
          expect(result["edges"].last["node"]["score"]).to eq(10000000)
        end
      end

      context "when no sort parameter is provided" do
        subject { execute_graphql(query, variables: { uid: raid.uid }) }

        it "defaults to published_at desc" do
          result = subject["data"]["raid"]["videos"]
          expect(result["edges"].count).to eq(3)
          expect(result["edges"].first["node"]["title"]).to eq("Video 3")
          expect(result["edges"].last["node"]["title"]).to eq("Video 1")
        end
      end
    end
  end
end
