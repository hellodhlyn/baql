class RaidVideo < ApplicationRecord
  def self.of(raid_uid:)
    raid = Raid.find_by(uid: raid_uid)
    return [] if raid.nil?

    RaidVideo.where(raid_type: raid.type, raid_boss: raid.boss, raid_terrain: raid.terrain)
  end

  def self.sync!(raid_uid:)
    raid = Raid.find_by(uid: raid_uid)
    return if raid.nil?

    youtube_client  = Youtube::Client.new
    search_queries  = search_queries(raid)
    published_after = 1.year.ago
    next_page_token = nil

    videos = []
    loop do
      result = youtube_client.search_videos(search_queries.join(" "), max_results: 50, published_after: published_after, next_page_token: next_page_token)
      result.items.each do |video|
        title = video.snippet.title
        score = title.gsub(",", "").match(/\d{8,}/)&.[](0)&.to_i
        next if score.blank? || search_queries.any? { |query| !title.include?(query) }

        videos << {
          title:         title,
          score:         score,
          youtube_id:    video.id.video_id,
          published_at:  video.snippet.published_at,
          thumbnail_url: video.snippet.thumbnails.high.url,
        }
      end

      next_page_token = result.next_page_token
      break if next_page_token.blank?
    end

    videos.each do |video|
      RaidVideo.create!(
        title:             video[:title],
        score:             video[:score],
        youtube_id:        video[:youtube_id],
        thumbnail_url:     video[:thumbnail_url],
        published_at:      video[:published_at],
        raid_type:         raid.type,
        raid_boss:         raid.boss,
        raid_terrain:      raid.terrain,
        raid_defense_type: raid.defense_type,
      )
    end
  end

  private

  def self.search_queries(raid)
    raid_type_name = case raid.type
      when "total_assault" then "総力戦"
      when "elimination"   then "大決戦"
      when "unlimit"       then "制約解除決戦"
    end

    terrain_name = case raid.terrain
      when "indoor"  then "室内"
      when "outdoor" then "屋外"
      when "street"  then "市街地"
    end

    boss_name = case raid.boss
      when "binah"           then "ビナー"
      when "chesed"          then "ケセド"
      when "hod"             then "ホド"
      when "shirokuro"       then "シロ&クロ"
      when "perorozilla"     then "ペロロジラ"
      when "goz"             then "ゴズ"
      when "hieronymus"      then "ヒエロニムス"
      when "kaiten-fx-mk0"   then "KAITEN FX Mk.0"
      when "gregorius"       then "グレゴリオ"
      when "hovercraft"      then "ホバークラフト"
      when "myouki-kurokage" then "クロカゲ"
      when "geburah"         then "ゲブラ"
    end

    [
      raid_type_name,
      terrain_name,
      boss_name,
    ].compact
  end
end
