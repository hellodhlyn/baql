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

ActiveRecord::Schema[8.0].define(version: 2025_02_20_173711) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "events", force: :cascade do |t|
    t.string "event_id", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.boolean "rerun", null: false
    t.datetime "since", null: false
    t.datetime "until", null: false
    t.string "image_url"
    t.jsonb "videos"
    t.jsonb "pickups"
    t.jsonb "tips"
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "event_index"
    t.index ["event_id"], name: "index_events_on_event_id", unique: true
    t.index ["since"], name: "index_events_on_since"
  end

  create_table "raids", force: :cascade do |t|
    t.string "raid_id", null: false
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
    t.index ["raid_id"], name: "index_raids_on_raid_id", unique: true
    t.index ["since"], name: "index_raids_on_since"
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
