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

ActiveRecord::Schema[8.0].define(version: 2025_10_23_130036) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "event_shop_resources", force: :cascade do |t|
    t.string "event_uid", null: false
    t.string "uid", null: false
    t.string "resource_type", null: false
    t.string "resource_uid", null: false
    t.integer "resource_amount", null: false
    t.string "payment_resource_type", null: false
    t.string "payment_resource_uid", null: false
    t.integer "payment_resource_amount", null: false
    t.integer "shop_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_uid"], name: "index_event_shop_resources_on_event_uid"
  end

  create_table "event_stage_reward_bonuses", force: :cascade do |t|
    t.string "reward_resource_type", null: false
    t.string "reward_resource_uid", null: false
    t.string "student_uid", null: false
    t.decimal "ratio", precision: 10, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reward_resource_type", "reward_resource_uid", "student_uid"], name: "idx_on_reward_resource_type_reward_resource_uid_stu_6cba816250", unique: true
    t.index ["student_uid"], name: "index_event_stage_reward_bonuses_on_student_uid"
  end

  create_table "event_stage_rewards", force: :cascade do |t|
    t.string "stage_uid", null: false
    t.string "reward_type", null: false
    t.string "reward_uid", null: false
    t.string "reward_requirement"
    t.integer "amount", null: false
    t.integer "amount_min"
    t.integer "amount_max"
    t.decimal "chance", precision: 10, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stage_uid", "reward_type", "reward_uid", "reward_requirement"], name: "idx_on_stage_uid_reward_type_reward_uid_reward_requ_02a1b757b1", unique: true
  end

  create_table "event_stages", force: :cascade do |t|
    t.string "uid", null: false
    t.string "event_uid", null: false
    t.string "name", null: false
    t.integer "difficulty", null: false
    t.string "index", null: false
    t.integer "entry_ap", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_uid"], name: "index_event_stages_on_event_uid"
    t.index ["uid"], name: "index_event_stages_on_uid", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.boolean "rerun", null: false
    t.datetime "since", null: false
    t.datetime "until", null: false
    t.string "image_url"
    t.jsonb "videos"
    t.jsonb "tips"
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "event_index"
    t.boolean "endless", default: false, null: false
  end

  create_table "furnitures", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.string "sub_category"
    t.integer "rarity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_furnitures_on_uid", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.string "sub_category"
    t.integer "rarity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_items_on_uid", unique: true
  end

  create_table "pickups", force: :cascade do |t|
    t.string "student_uid"
    t.string "fallback_student_name", null: false
    t.string "event_uid", null: false
    t.string "pickup_type", null: false
    t.datetime "since", null: false
    t.datetime "until"
    t.boolean "rerun", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_uid"], name: "index_pickups_on_event_uid"
    t.index ["student_uid"], name: "index_pickups_on_student_uid"
  end

  create_table "raid_statistics", force: :cascade do |t|
    t.string "student_uid", null: false
    t.bigint "raid_id", null: false
    t.string "defense_type", null: false
    t.string "difficulty", null: false
    t.bigint "slots_count", null: false
    t.jsonb "slots_by_tier", null: false
    t.bigint "assists_count", null: false
    t.jsonb "assists_by_tier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raid_id"], name: "index_raid_statistics_on_raid_id"
    t.index ["student_uid", "raid_id", "defense_type"], name: "idx_on_student_uid_raid_id_defense_type_0eac46e8be", unique: true
  end

  create_table "raid_videos", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "score", null: false
    t.string "youtube_id", null: false
    t.string "thumbnail_url", null: false
    t.datetime "published_at", null: false
    t.string "raid_type", null: false
    t.string "raid_boss", null: false
    t.string "raid_terrain", null: false
    t.string "raid_defense_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raid_type", "raid_boss", "raid_terrain", "raid_defense_type"], name: "idx_on_raid_type_raid_boss_raid_terrain_raid_defens_a2b1f3c8d3"
  end

  create_table "raids", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name", null: false
    t.string "boss", null: false
    t.string "type", null: false
    t.string "terrain"
    t.string "attack_type"
    t.string "defense_type"
    t.datetime "since", null: false
    t.datetime "until", null: false
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "raid_index_jp"
    t.boolean "rank_visible", default: false, null: false
    t.jsonb "defense_types", default: []
    t.index ["since"], name: "index_raids_on_since"
    t.index ["uid"], name: "index_raids_on_uid", unique: true
  end

  create_table "resources", force: :cascade do |t|
    t.string "type", null: false
    t.string "uid", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.string "sub_category"
    t.integer "rarity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type", "uid"], name: "index_resources_on_type_and_uid", unique: true
  end

  create_table "student_favorite_items", force: :cascade do |t|
    t.string "student_uid", null: false
    t.string "item_uid", null: false
    t.integer "exp", null: false
    t.integer "favorite_level", null: false
    t.boolean "favorited", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_uid"], name: "index_student_favorite_items_on_item_uid"
    t.index ["student_uid"], name: "index_student_favorite_items_on_student_uid"
  end

  create_table "student_skill_items", force: :cascade do |t|
    t.string "student_uid", null: false
    t.string "item_uid", null: false
    t.string "skill_type", null: false
    t.integer "skill_level", null: false
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_uid"], name: "index_student_skill_items_on_item_uid"
    t.index ["student_uid"], name: "index_student_skill_items_on_student_uid"
  end

  create_table "students", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name", null: false
    t.string "school", null: false
    t.integer "initial_tier", null: false
    t.string "attack_type", null: false
    t.string "defense_type", null: false
    t.string "role", null: false
    t.string "equipments"
    t.bigint "order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "multiclass_uid"
    t.string "schale_db_id"
    t.datetime "release_at"
    t.index ["uid"], name: "index_students_on_uid", unique: true
  end
end
