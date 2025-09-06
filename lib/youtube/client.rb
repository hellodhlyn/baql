class Youtube::Client
  attr_reader :client

  def initialize
    @client = Google::Apis::YoutubeV3::YouTubeService.new
    @client.key = ENV["YOUTUBE_API_KEY"]
  end

  def search_videos(query, max_results: 5, published_after: nil, next_page_token: nil)
    client.list_searches(
      :snippet,
      q: query,
      type: "video",
      max_results: max_results,
      published_after: published_after&.iso8601,
      page_token: next_page_token,
    )
  end
end
