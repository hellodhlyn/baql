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

ActiveRecord::Schema[8.0].define(version: 2025_05_17_094729) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["since"], name: "index_events_on_since"
    t.index ["uid"], name: "index_events_on_uid", unique: true
  end

  create_table "pickups", force: :cascade do |t|
    t.string "student_uid"
    t.string "fallback_student_name", null: false
    t.string "event_uid", null: false
    t.string "pickup_type", null: false
    t.datetime "since", null: false
    t.datetime "until", null: false
    t.boolean "rerun", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_uid"], name: "index_pickups_on_event_uid"
    t.index ["student_uid"], name: "index_pickups_on_student_uid"
  end

  create_table "raid_statistics", force: :cascade do |t|
    t.string "student_id", null: false
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
    t.index ["student_id", "raid_id", "defense_type"], name: "idx_on_student_id_raid_id_defense_type_5cd2daaa82", unique: true
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

  create_table "students", force: :cascade do |t|
    t.string "student_id", null: false
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
    t.string "multiclass_id"
    t.string "schale_db_id"
    t.datetime "release_at"
    t.index ["student_id"], name: "index_students_on_student_id", unique: true
  end
end
