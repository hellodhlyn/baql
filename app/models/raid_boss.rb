class RaidBoss < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::bosses::"
  RAID_TYPES = %w[raid unlimit allied].freeze

  ARMOR_TYPE_MAP = {
    "LightArmor"   => "light",
    "HeavyArmor"   => "heavy",
    "Unarmed"      => "special",
    "ElasticArmor" => "elastic",
  }.freeze

  ATTACK_TYPE_MAP = {
    "Normal"    => "normal",
    "Pierce"    => "piercing",
    "Explosion" => "explosive",
    "Mystic"    => "mystic",
    "Sonic"     => "sonic",
    "Chemical"  => "chemical",
  }.freeze

  DIFFICULTY_MAP = {
    5 => "insane",
    6 => "torment",
    7 => "lunatic",
  }.freeze

  # 총력전 시즌별 최고 난이도 (시즌 번호 기준)
  TOTAL_ASSAULT_MAX_DIFFICULTY_THRESHOLDS = [
    [74, "lunatic"],
    [47, "torment"],
    [26, "insane"],
    [ 1, "extreme"],
  ].freeze

  # DEPRECATED: raid_videos.raid_boss는 구 Raid 모델의 boss 필드 값을 그대로 사용하고 있어
  # RaidBoss.uid와 명칭이 다른 경우를 임시로 매핑. Raid 모델 제거 시 함께 정리 필요.
  VIDEO_BOSS_NAME_OVERRIDES = {
    "kurokage"     => "myouki-kurokage",
    "kaiten"       => "kaiten-fx-mk0",
    "perorodzilla" => "perorozilla",
  }.freeze

  belongs_to :event_content, foreign_key: :event_content_uid, primary_key: :uid, optional: true
  has_many :schedules, class_name: "RaidSchedule", foreign_key: :raid_boss_uid, primary_key: :uid

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :raid_type, inclusion: { in: RAID_TYPES }

  translatable :name

  def translation_key_prefix = baql_id

  def self.sync!
    data = SchaleDB::V1::Data.raids("kr")

    # uid→PathName map for Raid[] (used in schedule sync)
    raid_id_to_uid = {}

    # allied boss uid → terrain map (used in allied schedule sync)
    allied_boss_terrain = {}

    # 1. Raid[] → raid_type: "raid"
    raid_id_to_defense_type = {}
    raid_id_to_attack_type  = {}
    (data["Raid"] || []).each do |boss|
      uid          = boss["PathName"]
      defense_type = ARMOR_TYPE_MAP[boss["ArmorType"]]
      attack_type  = ATTACK_TYPE_MAP[boss["BulletTypeInsane"]]
      raid_id_to_uid[boss["Id"]]          = uid
      raid_id_to_defense_type[boss["Id"]] = defense_type
      raid_id_to_attack_type[boss["Id"]]  = attack_type
      find_or_initialize_by(uid: uid)
        .update!(baql_id: "#{BAQL_ID_PREFIX}#{uid}", raid_type: "raid", event_content_uid: nil)
    end

    # 2. MultiFloorRaid[] → raid_type: "unlimit"
    seen_unlimit_uids = {}
    (data["MultiFloorRaid"] || []).each do |boss|
      uid = boss["PathName"].sub(/_(specialarmor|lightarmor|heavyarmor|elasticarmor)$/i, "")
      next if seen_unlimit_uids[uid]

      seen_unlimit_uids[uid] = true
      find_or_initialize_by(uid: uid)
        .update!(baql_id: "#{BAQL_ID_PREFIX}#{uid}", raid_type: "unlimit", event_content_uid: nil)
    end

    # 3. InteractiveWorldRaid[] → raid_type: "allied"
    (data["InteractiveWorldRaid"] || []).each do |boss|
      uid = boss["PathName"]
      event_uid = boss["EventId"]&.to_s
      allied_boss_terrain[uid] = boss["Terrain"]&.first&.downcase
      find_or_initialize_by(uid: uid)
        .update!(baql_id: "#{BAQL_ID_PREFIX}#{uid}", raid_type: "allied", event_content_uid: event_uid)
    end

    # 4. WorldRaid[] → raid_type: "allied"
    (data["WorldRaid"] || []).each do |boss|
      uid = boss["PathName"]
      event_uid = boss["EventId"]&.to_s
      allied_boss_terrain[uid] = boss["Terrain"]&.first&.downcase
      find_or_initialize_by(uid: uid)
        .update!(baql_id: "#{BAQL_ID_PREFIX}#{uid}", raid_type: "allied", event_content_uid: event_uid)
    end

    # 5. Schedule sync
    raid_seasons = data["RaidSeasons"] || []
    region_map = { 0 => "jp", 1 => "gl" }

    raid_seasons.each_with_index do |server_seasons, index|
      region = region_map[index]
      next unless region  # skip CN (index 2)

      [
        { key: "Seasons",          raid_type: "total_assault" },
        { key: "EliminateSeasons", raid_type: "elimination"   },
      ].each do |entry|
        (server_seasons[entry[:key]] || []).each do |season|
          season_display = season["SeasonDisplay"]
          next if season_display == "BETA" || season_display.to_s.empty?

          season_index = season_display.to_i
          raid_id      = season["RaidId"]
          boss_uid     = raid_id_to_uid[raid_id]
          next unless boss_uid

          terrain   = season["Terrain"]&.downcase
          start_at  = Time.zone.at(season["Start"])
          end_at    = Time.zone.at(season["End"])
          defense_types_data = if entry[:raid_type] == "elimination"
            open_difficulty = season["OpenDifficulty"] || {}
            open_difficulty.filter_map do |armor_type, diff_level|
              defense_type = ARMOR_TYPE_MAP[armor_type]
              difficulty   = DIFFICULTY_MAP[diff_level]
              next unless defense_type && difficulty

              { "defense_type" => defense_type, "difficulty" => difficulty }
            end
          else
            # total_assault: 보스의 단일 defense_type + 시즌별 최고 난이도
            boss_defense_type = raid_id_to_defense_type[raid_id]
            difficulty = TOTAL_ASSAULT_MAX_DIFFICULTY_THRESHOLDS
              .find { |threshold, _| season_index >= threshold }
              &.last
            boss_defense_type && difficulty ? [{ "defense_type" => boss_defense_type, "difficulty" => difficulty }] : []
          end

          schedule_uid     = "#{region}_#{entry[:raid_type]}_#{season_index}"
          schedule_baql_id = "#{RaidSchedule::BAQL_ID_PREFIX}#{schedule_uid}"

          RaidSchedule.find_or_initialize_by(region: region, raid_type: entry[:raid_type], season_index: season_index)
            .update!(
              uid:           schedule_uid,
              baql_id:       schedule_baql_id,
              raid_boss_uid: boss_uid,
              terrain:       terrain,
              start_at:      start_at,
              end_at:        end_at,
              defense_types: defense_types_data,
              attack_type:   raid_id_to_attack_type[raid_id],
            )
        end
      end
    end

    # 5b. Allied schedule sync (EventContentSchedule 기반)
    boss_by_event_uid = where(raid_type: "allied").where.not(event_content_uid: nil)
      .each_with_object({}) do |boss, h|
        (h[boss.event_content_uid] ||= []) << boss.uid
      end

    unless boss_by_event_uid.empty?
      %w[jp gl].each do |region|
        entries = EventContentSchedule
          .where(event_content_uid: boss_by_event_uid.keys, region: region)
          .where.not(start_at: nil)
          .flat_map { |ecs| (boss_by_event_uid[ecs.event_content_uid] || []).map { |uid| [ecs, uid] } }
          .sort_by { |ecs, boss_uid| [ecs.start_at, boss_uid] }

        entries.each_with_index do |(ecs, boss_uid), i|
          season_index     = i + 1
          schedule_uid     = "#{region}_allied_#{season_index}"
          schedule_baql_id = "#{RaidSchedule::BAQL_ID_PREFIX}#{schedule_uid}"

          RaidSchedule.find_or_initialize_by(region: region, raid_type: "allied", season_index: season_index)
            .update!(
              uid:                       schedule_uid,
              baql_id:                   schedule_baql_id,
              raid_boss_uid:             boss_uid,
              terrain:                   allied_boss_terrain[boss_uid],
              start_at:               ecs.start_at,
              end_at:                 ecs.end_at,
              event_content_run_type: ecs.run_type,
            )
        end
      end
    end

    # 6. GL → JP schedule 매핑
    # boss+terrain+raid_type 조합별로, GL season_index를 초과하는 JP season_index 중 가장 가까운 것 (total_assault)
    # elimination은 JP/GL이 동일 season_index를 사용하므로 이상(>=) 기준
    # total_assault GL s46 이하는 순서 보장이 어려워 null 처리
    schedule_index = RaidSchedule.all.each_with_object({}) do |s, h|
      key = [s.raid_boss_uid, s.terrain, s.raid_type]
      (h[key] ||= { "jp" => [], "gl" => [] })[s.region] << s
    end
    schedule_index.each_value do |by_region|
      by_region.each_value { |arr| arr.sort_by!(&:season_index) }
    end

    schedule_index.each_value do |by_region|
      jp_schedules = by_region["jp"] || []
      gl_schedules = by_region["gl"] || []

      gl_schedules.each do |gl|
        jp = if gl.raid_type == "total_assault"
          jp_schedules.find { |s| s.season_index > gl.season_index }
        else
          jp_schedules.find { |s| s.season_index >= gl.season_index }
        end
        gl.update_columns(jp_season_index: jp&.season_index)
      end
    end

    # total_assault GL s46 이하는 순서 보장 불가 → null
    RaidSchedule.where(region: "gl", raid_type: "total_assault")
                .where("season_index <= 46")
                .update_all(jp_season_index: nil)

    # 6b. GL 총력전 defense_types를 JP season_index 기준으로 재계산
    jp_schedules_by_season = RaidSchedule.where(region: "jp", raid_type: "total_assault")
      .index_by(&:season_index)

    RaidSchedule.where(region: "gl", raid_type: "total_assault").find_each do |gl|
        jp_season_index = gl.jp_season_index
        next unless jp_season_index

        jp = jp_schedules_by_season[jp_season_index]
        next unless jp

        boss_defense_type = jp.defense_types.first&.defense_type
        difficulty = TOTAL_ASSAULT_MAX_DIFFICULTY_THRESHOLDS
          .find { |threshold, _| jp_season_index >= threshold }
          &.last
        next unless boss_defense_type && difficulty

        gl.update_columns(defense_types: [{ "defense_type" => boss_defense_type, "difficulty" => difficulty }])
      end

    # 7. Translation sync
    Constants::LANGUAGE_MAP.each do |data_path, lang|
      lang_data = SchaleDB::V1::Data.raids(data_path)

      # Raid[]
      (lang_data["Raid"] || []).each do |boss|
        record = find_by(uid: boss["PathName"])
        record&.set_name(boss["Name"], lang)
      end

      # MultiFloorRaid[]
      seen_unlimit_uids_for_trans = {}
      (lang_data["MultiFloorRaid"] || []).each do |boss|
        uid = boss["PathName"].sub(/_(specialarmor|lightarmor|heavyarmor|elasticarmor)$/i, "")
        next if seen_unlimit_uids_for_trans[uid]

        seen_unlimit_uids_for_trans[uid] = true
        record = find_by(uid: uid)
        record&.set_name(boss["Name"], lang)
      end

      # InteractiveWorldRaid[]
      (lang_data["InteractiveWorldRaid"] || []).each do |boss|
        record = find_by(uid: boss["PathName"])
        record&.set_name(boss["Name"], lang)
      end

      # WorldRaid[]
      (lang_data["WorldRaid"] || []).each do |boss|
        record = find_by(uid: boss["PathName"])
        record&.set_name(boss["Name"], lang)
      end
    end

    nil
  end
end
