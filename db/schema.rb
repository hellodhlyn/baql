# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_22_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "category", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "end_at", null: false
    t.integer "multiplier", null: false
    t.string "region", null: false
    t.datetime "start_at", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid", "region"], name: "index_campaigns_on_uid_and_region", unique: true
  end

  create_table "currencies", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.integer "rarity", null: false
    t.jsonb "raw_data"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_currencies_on_uid", unique: true
  end

  create_table "deprecated_event_shop_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_uid", null: false
    t.integer "payment_resource_amount", null: false
    t.string "payment_resource_type", null: false
    t.string "payment_resource_uid", null: false
    t.integer "resource_amount", null: false
    t.string "resource_type", null: false
    t.string "resource_uid", null: false
    t.integer "shop_amount"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["event_uid"], name: "index_deprecated_event_shop_resources_on_event_uid"
  end

  create_table "emblems", force: :cascade do |t|
    t.string "baql_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.jsonb "image_asset_keys", default: {}, null: false
    t.integer "rarity", null: false
    t.jsonb "raw_data", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_emblems_on_uid", unique: true
  end

  create_table "equipments", force: :cascade do |t|
    t.string "baql_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.integer "rarity", null: false
    t.jsonb "raw_data"
    t.string "sub_category"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_equipments_on_uid", unique: true
  end

  create_table "event_content_run_bonuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_content_run_id", null: false
    t.decimal "percentage", precision: 10, scale: 4, null: false
    t.integer "position", null: false
    t.string "reward_type", null: false
    t.string "reward_uid", null: false
    t.string "student_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["event_content_run_id", "student_uid", "reward_type", "reward_uid"], name: "idx_event_run_bonuses_unique", unique: true
    t.index ["reward_type", "reward_uid"], name: "index_event_content_run_bonuses_on_reward_type_and_reward_uid"
    t.index ["student_uid"], name: "index_event_content_run_bonuses_on_student_uid"
  end

  create_table "event_content_run_minigames", force: :cascade do |t|
    t.jsonb "config", null: false
    t.datetime "created_at", null: false
    t.bigint "event_content_run_id", null: false
    t.string "minigame_type", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["event_content_run_id", "minigame_type"], name: "idx_event_run_minigames_unique", unique: true
  end

  create_table "event_content_run_missions", force: :cascade do |t|
    t.string "category", null: false
    t.boolean "completion_extension", null: false
    t.string "completion_reference_mission_uid"
    t.integer "completion_reference_required_count", default: 0, null: false
    t.integer "condition_count", null: false
    t.jsonb "condition_parameter_tags", null: false
    t.jsonb "condition_parameters", null: false
    t.integer "condition_reward_amount"
    t.string "condition_reward_type"
    t.string "condition_reward_uid"
    t.string "condition_type", null: false
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.bigint "event_content_run_id", null: false
    t.jsonb "localizations", null: false
    t.integer "position", null: false
    t.string "pre_mission_uid"
    t.string "reset_type", null: false
    t.integer "reward_amount", null: false
    t.string "reward_type", null: false
    t.string "reward_uid", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_reward_type", "condition_reward_uid"], name: "idx_event_run_missions_condition_reward"
    t.index ["event_content_run_id", "position"], name: "idx_event_run_missions_position"
    t.index ["event_content_run_id", "uid"], name: "idx_event_run_missions_unique", unique: true
    t.index ["reward_type", "reward_uid"], name: "idx_event_run_missions_reward"
  end

  create_table "event_content_run_shop_purchase_tiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_content_run_shop_resource_id", null: false
    t.string "payment_resource_type", null: false
    t.string "payment_resource_uid", null: false
    t.integer "quantity"
    t.integer "start_quantity", null: false
    t.integer "tier_index", null: false
    t.integer "unit_price", null: false
    t.datetime "updated_at", null: false
    t.index ["event_content_run_shop_resource_id", "tier_index"], name: "idx_event_run_shop_tiers_unique", unique: true
  end

  create_table "event_content_run_shop_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_content_run_id", null: false
    t.integer "payment_resource_amount", null: false
    t.string "payment_resource_type", null: false
    t.string "payment_resource_uid", null: false
    t.integer "position", null: false
    t.integer "resource_amount", null: false
    t.string "resource_type", null: false
    t.string "resource_uid", null: false
    t.integer "shop_amount"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["event_content_run_id", "uid"], name: "idx_event_run_shop_resources_unique", unique: true
    t.index ["payment_resource_type", "payment_resource_uid"], name: "idx_event_run_shop_payment_resource"
    t.index ["resource_type", "resource_uid"], name: "idx_on_resource_type_resource_uid_60b837f229"
  end

  create_table "event_content_run_stage_rewards", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.bigint "event_content_run_stage_id", null: false
    t.integer "position", null: false
    t.decimal "probability", precision: 10, scale: 4, null: false
    t.string "reward_type", null: false
    t.string "reward_uid", null: false
    t.string "tag", null: false
    t.datetime "updated_at", null: false
    t.index ["event_content_run_stage_id", "position"], name: "idx_on_event_content_run_stage_id_position_c8c204a050", unique: true
    t.index ["reward_type", "reward_uid"], name: "idx_on_reward_type_reward_uid_2ba643203a"
  end

  create_table "event_content_run_stages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "enter_cost_amount", null: false
    t.string "enter_cost_type", null: false
    t.string "enter_cost_uid", null: false
    t.bigint "event_content_run_id", null: false
    t.integer "position", null: false
    t.integer "stage_index", null: false
    t.string "stage_number", null: false
    t.string "stage_type", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["enter_cost_type", "enter_cost_uid"], name: "idx_on_enter_cost_type_enter_cost_uid_0e7637a5d6"
    t.index ["event_content_run_id", "uid"], name: "index_event_content_run_stages_on_event_content_run_id_and_uid", unique: true
  end

  create_table "event_content_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_content_uid", null: false
    t.integer "position", null: false
    t.string "run_type", null: false
    t.bigint "source_event_content_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["event_content_uid", "run_type"], name: "index_event_content_runs_on_event_content_uid_and_run_type", unique: true
  end

  create_table "event_content_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_at"
    t.string "event_content_uid", null: false
    t.string "region", null: false
    t.string "run_type", null: false
    t.datetime "start_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_content_uid", "region", "run_type"], name: "idx_on_event_content_uid_region_run_type_515a15f63c", unique: true
    t.index ["region", "start_at", "end_at"], name: "idx_on_region_start_at_end_at_636d06fff6"
  end

  create_table "event_contents", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "raw_data_first"
    t.jsonb "raw_data_rerun"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_event_contents_on_uid", unique: true
  end

  create_table "event_stage_reward_bonuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "ratio", precision: 10, scale: 4
    t.string "reward_resource_type", null: false
    t.string "reward_resource_uid", null: false
    t.string "student_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["reward_resource_type", "reward_resource_uid", "student_uid"], name: "idx_on_reward_resource_type_reward_resource_uid_stu_6cba816250", unique: true
    t.index ["student_uid"], name: "index_event_stage_reward_bonuses_on_student_uid"
  end

  create_table "event_stage_rewards", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "amount_max"
    t.integer "amount_min"
    t.decimal "chance", precision: 10, scale: 4
    t.datetime "created_at", null: false
    t.string "reward_requirement"
    t.string "reward_type", null: false
    t.string "reward_uid", null: false
    t.string "stage_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["stage_uid", "reward_type", "reward_uid", "reward_requirement"], name: "idx_on_stage_uid_reward_type_reward_uid_reward_requ_02a1b757b1", unique: true
  end

  create_table "event_stages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "difficulty", null: false
    t.integer "entry_ap", null: false
    t.string "event_uid", null: false
    t.string "index", null: false
    t.string "name", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["event_uid"], name: "index_event_stages_on_event_uid"
    t.index ["uid"], name: "index_event_stages_on_uid", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "endless", default: false, null: false
    t.bigint "event_index"
    t.string "image_url"
    t.string "name", null: false
    t.boolean "rerun", null: false
    t.datetime "since", null: false
    t.text "summary"
    t.string "tags", default: [], array: true
    t.jsonb "tips"
    t.string "type", null: false
    t.string "uid", null: false
    t.datetime "until", null: false
    t.datetime "updated_at", null: false
    t.jsonb "videos"
    t.index ["since"], name: "index_events_on_since"
    t.index ["uid"], name: "index_events_on_uid", unique: true
  end

  create_table "furniture_catalog_states", force: :cascade do |t|
    t.datetime "assets_imported_at"
    t.boolean "assets_ready", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "data_ready", default: false, null: false
    t.string "database_sha256"
    t.integer "furniture_count", default: 0, null: false
    t.datetime "imported_at"
    t.integer "preview_count", default: 0, null: false
    t.integer "theme_count", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "furniture_template_previews", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.string "furniture_theme_uid", null: false
    t.string "image_asset_key"
    t.string "thumbnail_asset_key"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["furniture_theme_uid", "display_order"], name: "index_furniture_previews_on_theme_and_display_order", unique: true
    t.index ["uid"], name: "index_furniture_template_previews_on_uid", unique: true
  end

  create_table "furniture_themes", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_furniture_themes_on_uid", unique: true
  end

  create_table "furnitures", force: :cascade do |t|
    t.string "baql_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "image_asset_key"
    t.boolean "in_catalog", default: false, null: false
    t.integer "rarity", null: false
    t.jsonb "raw_data"
    t.string "sub_category"
    t.string "tags", default: [], null: false, array: true
    t.string "theme_uid"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["theme_uid"], name: "index_furnitures_on_theme_uid"
    t.index ["uid"], name: "index_furnitures_on_uid", unique: true
  end

  create_table "gacha_groups", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "raw_data", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_gacha_groups_on_uid", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.string "baql_id", default: "", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.integer "rarity", null: false
    t.jsonb "raw_data"
    t.string "sub_category"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_items_on_uid", unique: true
  end

  create_table "joint_firing_drill_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "drill_uid", null: false
    t.datetime "end_at"
    t.string "region", null: false
    t.datetime "start_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drill_uid", "region"], name: "index_joint_firing_drill_schedules_on_drill_uid_and_region", unique: true
    t.index ["drill_uid"], name: "index_joint_firing_drill_schedules_on_drill_uid"
  end

  create_table "joint_firing_drills", force: :cascade do |t|
    t.boolean "confirmed", default: true, null: false
    t.datetime "created_at", null: false
    t.string "defense_type", null: false
    t.string "drill_type", null: false
    t.integer "season", null: false
    t.string "terrain", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["season"], name: "index_joint_firing_drills_on_season", unique: true
    t.index ["uid"], name: "index_joint_firing_drills_on_uid", unique: true
  end

  create_table "main_story_chapters", force: :cascade do |t|
    t.string "baql_id", null: false
    t.integer "chapter_number", null: false
    t.datetime "created_at", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "volume_uid", null: false
    t.index ["uid"], name: "index_main_story_chapters_on_uid", unique: true
    t.index ["volume_uid"], name: "index_main_story_chapters_on_volume_uid"
  end

  create_table "main_story_part_schedules", force: :cascade do |t|
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.string "part_uid", null: false
    t.string "region", null: false
    t.datetime "released_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_uid", "region"], name: "index_main_story_part_schedules_on_part_uid_and_region", unique: true
  end

  create_table "main_story_parts", force: :cascade do |t|
    t.string "baql_id", null: false
    t.string "chapter_uid", null: false
    t.datetime "created_at", null: false
    t.integer "episode_end"
    t.integer "episode_start"
    t.integer "sort_order", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter_uid"], name: "index_main_story_parts_on_chapter_uid"
    t.index ["uid"], name: "index_main_story_parts_on_uid", unique: true
  end

  create_table "main_story_volumes", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.integer "season", null: false
    t.integer "sort_order", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["sort_order"], name: "index_main_story_volumes_on_sort_order"
    t.index ["uid"], name: "index_main_story_volumes_on_uid", unique: true
  end

  create_table "mini_event_content_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_at", null: false
    t.string "mini_event_content_uid", null: false
    t.integer "occurrence", null: false
    t.string "region", null: false
    t.datetime "start_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mini_event_content_uid", "region", "occurrence"], name: "index_mini_event_content_schedules_unique", unique: true
    t.index ["region", "start_at", "end_at"], name: "idx_on_region_start_at_end_at_dbdc045b92"
  end

  create_table "mini_event_contents", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_mini_event_contents_on_uid", unique: true
  end

  create_table "mini_stories", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.integer "episode_count", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_mini_stories_on_uid", unique: true
  end

  create_table "mini_story_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "mini_story_uid", null: false
    t.string "region", null: false
    t.datetime "released_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mini_story_uid", "region"], name: "index_mini_story_schedules_on_mini_story_uid_and_region", unique: true
    t.index ["region", "released_at"], name: "index_mini_story_schedules_on_region_and_released_at"
  end

  create_table "pickups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_uid", null: false
    t.string "fallback_student_name", null: false
    t.string "pickup_type", null: false
    t.boolean "rerun", null: false
    t.datetime "since", null: false
    t.string "student_uid"
    t.datetime "until"
    t.datetime "updated_at", null: false
    t.index ["event_uid"], name: "index_pickups_on_event_uid"
    t.index ["student_uid"], name: "index_pickups_on_student_uid"
  end

  create_table "raid_bosses", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.string "event_content_uid"
    t.string "raid_type", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["event_content_uid"], name: "index_raid_bosses_on_event_content_uid"
    t.index ["uid"], name: "index_raid_bosses_on_uid", unique: true
  end

  create_table "raid_schedules", force: :cascade do |t|
    t.string "attack_type"
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "defense_types", default: []
    t.datetime "end_at"
    t.string "event_content_run_type"
    t.integer "jp_season_index"
    t.string "raid_boss_uid", null: false
    t.string "raid_type", null: false
    t.string "region", null: false
    t.integer "season_index", null: false
    t.datetime "start_at"
    t.string "terrain", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["raid_boss_uid"], name: "index_raid_schedules_on_raid_boss_uid"
    t.index ["raid_type", "jp_season_index"], name: "index_raid_schedules_on_raid_type_and_jp_season_index"
    t.index ["region", "raid_type", "season_index"], name: "index_raid_schedules_on_region_and_raid_type_and_season_index", unique: true
    t.index ["region", "start_at", "end_at"], name: "index_raid_schedules_on_region_and_start_at_and_end_at"
    t.index ["uid"], name: "index_raid_schedules_on_uid", unique: true
  end

  create_table "raid_statistics", force: :cascade do |t|
    t.jsonb "assists_by_tier", null: false
    t.bigint "assists_count", null: false
    t.datetime "created_at", null: false
    t.string "defense_type", null: false
    t.string "difficulty", null: false
    t.bigint "raid_id", null: false
    t.jsonb "slots_by_tier", null: false
    t.bigint "slots_count", null: false
    t.string "student_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["raid_id"], name: "index_raid_statistics_on_raid_id"
    t.index ["student_uid", "raid_id", "defense_type"], name: "idx_on_student_uid_raid_id_defense_type_0eac46e8be", unique: true
  end

  create_table "raid_videos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "published_at", null: false
    t.string "raid_boss", null: false
    t.string "raid_defense_type", null: false
    t.string "raid_terrain", null: false
    t.string "raid_type", null: false
    t.bigint "score", null: false
    t.string "thumbnail_url", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "youtube_id", null: false
    t.index ["raid_type", "raid_boss", "raid_terrain", "raid_defense_type"], name: "idx_on_raid_type_raid_boss_raid_terrain_raid_defens_a2b1f3c8d3"
  end

  create_table "raids", force: :cascade do |t|
    t.string "attack_type"
    t.string "boss", null: false
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.jsonb "defense_types", default: []
    t.string "name", null: false
    t.bigint "raid_index_jp"
    t.boolean "rank_visible", default: false, null: false
    t.datetime "since", null: false
    t.string "terrain"
    t.string "type", null: false
    t.string "uid", null: false
    t.datetime "until", null: false
    t.datetime "updated_at", null: false
    t.index ["since"], name: "index_raids_on_since"
    t.index ["uid"], name: "index_raids_on_uid", unique: true
  end

  create_table "recruitment_group_contents", force: :cascade do |t|
    t.string "content_run_type"
    t.string "content_type", null: false
    t.string "content_uid", null: false
    t.datetime "created_at", null: false
    t.string "recruitment_group_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["content_type", "content_uid", "content_run_type"], name: "idx_rg_contents_on_content"
    t.index ["recruitment_group_uid", "content_type", "content_uid", "content_run_type"], name: "idx_rg_contents_unique_with_run_type", unique: true, where: "(content_run_type IS NOT NULL)"
    t.index ["recruitment_group_uid", "content_type", "content_uid"], name: "idx_rg_contents_unique_without_run_type", unique: true, where: "(content_run_type IS NULL)"
    t.index ["recruitment_group_uid"], name: "index_recruitment_group_contents_on_recruitment_group_uid"
  end

  create_table "recruitment_groups", force: :cascade do |t|
    t.string "baql_id", null: false
    t.string "content_type"
    t.string "content_uid"
    t.datetime "created_at", null: false
    t.datetime "end_at"
    t.string "recruitment_type", null: false
    t.datetime "start_at", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["content_type", "content_uid"], name: "index_recruitment_groups_on_content_type_and_content_uid"
    t.index ["uid"], name: "index_recruitment_groups_on_uid", unique: true
  end

  create_table "recruitments", force: :cascade do |t|
    t.string "baql_id", null: false
    t.datetime "created_at", null: false
    t.boolean "pickup", default: true, null: false
    t.string "recruitment_group_uid", null: false
    t.string "recruitment_type", null: false
    t.boolean "rerun", default: false, null: false
    t.string "student_name", null: false
    t.string "student_uid"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["recruitment_group_uid"], name: "index_recruitments_on_recruitment_group_uid"
    t.index ["student_uid"], name: "index_recruitments_on_student_uid"
    t.index ["uid"], name: "index_recruitments_on_uid", unique: true
  end

  create_table "resources", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "rarity", null: false
    t.string "sub_category"
    t.string "type", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["type", "uid"], name: "index_resources_on_type_and_uid", unique: true
  end

  create_table "stages", force: :cascade do |t|
    t.integer "area"
    t.string "baql_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.integer "difficulty"
    t.integer "level"
    t.jsonb "raw_data", null: false
    t.string "stage_number"
    t.string "stage_type"
    t.string "terrain"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_stages_on_category"
    t.index ["uid"], name: "index_stages_on_uid", unique: true
  end

  create_table "student_catalogs", force: :cascade do |t|
    t.string "assets_version"
    t.string "client_version"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "database_sha256", null: false
    t.string "region", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["region"], name: "index_student_catalogs_on_region", unique: true
    t.index ["version"], name: "index_student_catalogs_on_version"
  end

  create_table "student_favorite_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "exp", null: false
    t.integer "favorite_level", null: false
    t.boolean "favorited", null: false
    t.string "item_uid", null: false
    t.string "student_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["item_uid"], name: "index_student_favorite_items_on_item_uid"
    t.index ["student_uid"], name: "index_student_favorite_items_on_student_uid"
  end

  create_table "student_gear_growth_items", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.integer "gear_tier", null: false
    t.string "item_uid", null: false
    t.string "student_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["item_uid"], name: "index_student_gear_growth_items_on_item_uid"
    t.index ["student_uid", "gear_tier", "item_uid"], name: "idx_on_student_uid_gear_tier_item_uid_0169390a0c", unique: true
  end

  create_table "student_skill_items", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "item_uid", null: false
    t.integer "skill_level", null: false
    t.string "skill_type", null: false
    t.string "student_uid", null: false
    t.datetime "updated_at", null: false
    t.index ["item_uid"], name: "index_student_skill_items_on_item_uid"
    t.index ["student_uid"], name: "index_student_skill_items_on_student_uid"
  end

  create_table "student_skills", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon_asset_key"
    t.jsonb "levels", default: [], null: false
    t.jsonb "links", default: {}, null: false
    t.jsonb "localizations", default: {}, null: false
    t.string "name", null: false
    t.string "skill_type", null: false
    t.string "student_uid", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["student_uid", "skill_type"], name: "index_student_skills_on_student_uid_and_skill_type"
    t.index ["student_uid", "uid"], name: "index_student_skills_on_student_uid_and_uid", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.string "alt_names", default: [], array: true
    t.datetime "archive_at"
    t.string "attack_type", null: false
    t.date "birthday"
    t.jsonb "catalog_data", default: {}, null: false
    t.string "character_group_uid"
    t.string "club"
    t.datetime "created_at", null: false
    t.string "defense_type", null: false
    t.string "equipments"
    t.string "family_name"
    t.string "gear_name"
    t.integer "initial_tier", null: false
    t.datetime "jp_release_at"
    t.string "multiclass_uid"
    t.string "name", null: false
    t.bigint "order", null: false
    t.string "personal_name"
    t.string "position"
    t.jsonb "raw_data", default: {}, null: false
    t.datetime "release_at"
    t.string "role", null: false
    t.string "schale_db_id"
    t.string "school", null: false
    t.string "student_variant_uid"
    t.string "tactic_role"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["character_group_uid"], name: "index_students_on_character_group_uid"
    t.index ["jp_release_at"], name: "index_students_on_jp_release_at"
    t.index ["student_variant_uid"], name: "index_students_on_student_variant_uid"
    t.index ["uid"], name: "index_students_on_uid", unique: true
  end

  create_table "translations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "language", null: false
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.index ["key", "language"], name: "index_translations_on_key_and_language", unique: true
  end

  add_foreign_key "furniture_template_previews", "furniture_themes", column: "furniture_theme_uid", primary_key: "uid", on_delete: :cascade
  add_foreign_key "furnitures", "furniture_themes", column: "theme_uid", primary_key: "uid", on_delete: :nullify
  add_foreign_key "joint_firing_drill_schedules", "joint_firing_drills", column: "drill_uid", primary_key: "uid"
end
